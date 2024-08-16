from mc.net.minecraft.game.entity.animal.EntityAnimal import EntityAnimal

class EntitySheep(EntityAnimal):

    def __init__(self, world):
        super().__init__(world)
        self.texture = 'mob/sheep.png'
        self.setSize(0.9, 1.3)

    def _writeEntityToNBT(self, compound):
        super()._writeEntityToNBT(compound)

    def _readEntityFromNBT(self, compound):
        super()._readEntityFromNBT(compound)

    def _getEntityString(self):
        return 'Sheep'
