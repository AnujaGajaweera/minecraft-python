from mc.net.minecraft.game.entity.EntityLiving import EntityLiving

import math

class EntityCreature(EntityLiving):

    def __init__(self, world):
        super().__init__(world)
        self.__pathToEntity = None
        self.__playerToAttack = None
        self._hasAttacked = False

    def _updatePlayerActionState(self):
        self._hasAttacked = False
        if not self.__playerToAttack:
            self.__playerToAttack = self._findPlayerToAttack()
            if self.__playerToAttack:
                self.__pathToEntity = self._worldObj.pathFinder.createEntityPathTo(
                    self, self.__playerToAttack, 16.0
                )
        elif not self.__playerToAttack.isEntityAlive():
            self.__playerToAttack = None
        else:
            xd = self.__playerToAttack.posX - self.posX
            yd = self.__playerToAttack.posY - self.posY
            zd = self.__playerToAttack.posZ - self.posZ
            d = math.sqrt(xd * xd + yd * yd + zd * zd)
            if not self._worldObj.rayTraceBlocks(
                self.boundingBox.getAverageEdgeLength(),
                self.__playerToAttack.boundingBox.getAverageEdgeLength()
            ):
                self._attackEntity(self.__playerToAttack, d)

        if self._hasAttacked:
            self._moveStrafing = 0.0
            self._moveForward = 0.0
            self._isJumping = False
            return

        if not self.__playerToAttack or self.__pathToEntity and \
             self._rand.nextInt(20) != 0:
            if not self.__pathToEntity or self._rand.nextInt(100) == 0:
                toX = -1
                toY = -1
                toZ = -1
                lastWeight = -99999.0
                for i in range(200):
                    x = self.posX + self._rand.nextInt(21) - 10.0
                    y = self.posY + self._rand.nextInt(9) - 4.0
                    z = self.posZ + self._rand.nextInt(21) - 10.0
                    weight = self._getBlockPathWeight(x, y, z)
                    if weight > lastWeight:
                        lastWeight = weight
                        toX = x
                        toY = y
                        toZ = z

                if toX > 0:
                    self.__pathToEntity = self._worldObj.pathFinder.createEntityPath(
                        self, toX, toY, toZ, 16.0
                    )
        else:
            self.__pathToEntity = self._worldObj.pathFinder.createEntityPathTo(
                self, self.__playerToAttack, 16.0
            )

        isInWater = self.handleWaterMovement()
        isInLava = self.handleLavaMovement()
        if self.__pathToEntity:
            posVec = self.__pathToEntity.getPosition(self)
            w = self.width * 2.0
            while posVec:
                z = self.posZ
                y = self.posY
                x = self.posX
                x -= posVec.xCoord
                y -= posVec.yCoord
                z -= posVec.zCoord
                if x * x + y * y + z * z >= w * w or posVec.yCoord > self.posY:
                    break

                self.__pathToEntity.incrementPathIndex()
                if self.__pathToEntity.isFinished():
                    posVec = None
                    self.__pathToEntity = None
                else:
                    posVec = self.__pathToEntity.getPosition(self)

            self._isJumping = False
            if posVec:
                xd = posVec.xCoord - self.posX
                yd = posVec.yCoord - self.posY
                zd = posVec.zCoord - self.posZ
                self.rotationYaw = (math.atan2(zd, xd) * 180.0 / math.pi) - 90.0
                self._moveForward = self._moveSpeed
                if yd > 0.0:
                    self._isJumping = True
        else:
            if isInWater or isInLava:
                self._isJumping = self._rand.nextFloat() < 0.8

    def _attackEntity(self, entity, distance):
        pass

    def _getBlockPathWeight(self, x, y, z):
        return 0.0

    def _findPlayerToAttack(self):
        return None

    def getCanSpawnHere(self, x, y, z):
        return self._getBlockPathWeight(int(x), int(y), int(z)) >= 0.0
