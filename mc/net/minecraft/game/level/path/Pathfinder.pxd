# cython: language_level=3

cimport cython

from mc.net.minecraft.game.level.World cimport World
from mc.net.minecraft.game.entity.Entity cimport Entity

@cython.final
cdef class Pathfinder:

    cdef:
        World __worldMap
        object __path
        dict __pointMap
        list __pathOptions

    cdef __addToPath(self, Entity entity, float x, float y, float z, float distance)
    cdef __getSafePoint(self, Entity entity, int x, int y, int z,
                        sizePoint, int yOffset)
    cdef __openPoint(self, int x, int y, int z)
    cdef bint __getVerticalOffset(self, int x, int y, int z, sizePoint)
    @staticmethod
    cdef __createEntityPath(point)
