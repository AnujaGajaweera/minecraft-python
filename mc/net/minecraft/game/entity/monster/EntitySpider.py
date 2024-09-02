from mc.net.minecraft.game.entity.monster.EntityMob import EntityMob

import math

class EntitySpider(EntityMob):

    def __init__(self, world):
        super().__init__(world)
        self._texture = 'mob/spider.png'
        self.setSize(1.4, 0.9)
        self._moveSpeed = 0.8

    def _attackEntity(self, entity, distance):
        if distance > 2.0 and distance < 6.0 and self._rand.nextInt(5) == 0:
            if self.onGround:
                xd = entity.posX - self.posX
                zd = entity.posZ - self.posZ
                d = math.sqrt(xd * xd + zd * zd)
                self.motionX = xd / d * 0.5 * 0.8 + self.motionX * 0.2
                self.motionZ = zd / d * 0.5 * 0.8 + self.motionZ * 0.2
                self.motionY = 0.4
                return
        else:
            super()._attackEntity(entity, distance)

    def _writeEntityToNBT(self, compound):
        super()._writeEntityToNBT(compound)

    def _readEntityFromNBT(self, compound):
        super()._readEntityFromNBT(compound)

    def _getEntityString(self):
        return 'Spider'
