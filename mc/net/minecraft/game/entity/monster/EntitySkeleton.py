from mc.net.minecraft.game.entity.monster.EntityMob import EntityMob
from mc.net.minecraft.game.entity.projectile.EntityArrow import EntityArrow

import math

class EntitySkeleton(EntityMob):

    def __init__(self, world):
        super().__init__(world)
        self.texture = 'mob/skeleton.png'

    def _attackEntity(self, entity, distance):
        if distance >= 10.0:
            return

        xd = entity.posX - self.posX
        zd = entity.posZ - self.posZ
        if self.attackTime == 0:
            arrow = EntityArrow(self._worldObj, self)
            arrow.posY += 1
            yd = entity.posY - arrow.posY
            d = math.sqrt(xd * xd + zd * zd) * 0.4
            self._worldObj.playSoundAtEntity(
                self, 'random.bow', 1.0, 1.0 / (self._rand.nextFloat() * 0.4 + 0.8)
            )
            self._worldObj.spawnEntityInWorld(arrow)
            arrow.setArrowHeading(xd, yd + d, zd, 0.6, 4.0)
            self.attackTime = 30

        self.rotationYaw = (math.atan2(zd, xd) * 180.0 / math.pi) - 90.0
        self._hasAttacked = True

    def _writeEntityToNBT(self, compound):
        super()._writeEntityToNBT(compound)

    def _readEntityFromNBT(self, compound):
        super()._readEntityFromNBT(compound)

    def _getEntityString(self):
        return 'Skeleton'
