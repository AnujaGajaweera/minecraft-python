from mc.net.minecraft.game.entity.monster.EntityMob import EntityMob

class EntityZombie(EntityMob):

    def __init__(self, world):
        super().__init__(world)
        self.texture = 'mob/zombie.png'
        self._moveSpeed = 0.5
        self._attackStrength = 5

    def _getEntityString(self):
        return 'Zombie'
