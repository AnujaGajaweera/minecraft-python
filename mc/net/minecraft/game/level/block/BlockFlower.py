from mc.net.minecraft.game.level.block.Block import Block
from mc.net.minecraft.game.level.material.Material import Material

class BlockFlower(Block):

    def __init__(self, blocks, blockId, tex):
        super().__init__(blocks, blockId, tex, Material.plants)
        self.blockIndexInTexture = tex
        self._setTickOnLoad(True)
        self._setBlockBounds(0.3, 0.0, 0.3, 0.7, 0.6, 0.7)

    def canPlaceBlockAt(self, world, x, y, z):
        return self._canThisPlantGrowOnThisBlockID(world.getBlockId(x, y - 1, z))

    def _canThisPlantGrowOnThisBlockID(self, blockId):
        return blockId == self.blocks.grass.blockID or \
               blockId == self.blocks.dirt.blockID or \
               blockId == self.blocks.tilledField.blockID

    def onNeighborBlockChange(self, world, x, y, z, blockType):
        super().onNeighborBlockChange(world, x, y, z, blockType)
        self._checkFlowerChange(world, x, y, z)

    def updateTick(self, world, x, y, z, random):
        self._checkFlowerChange(world, x, y, z)

    def _checkFlowerChange(self, world, x, y, z):
        below = world.getBlockId(x, y - 1, z)
        if not world.isHalfLit(x, y, z) or not \
           self._canThisPlantGrowOnThisBlockID(below):
            world.setBlockWithNotify(x, y, z, 0)

    def getCollisionBoundingBoxFromPool(self, x, y, z):
        return None

    def isOpaqueCube(self):
        return False

    def renderAsNormalBlock(self):
        return False

    def getRenderType(self):
        return 1
