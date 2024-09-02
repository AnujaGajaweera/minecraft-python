# cython: language_level=3

cimport cython

from mc.net.minecraft.game.level.World cimport World

@cython.final
cdef class Light:

    cdef:
        int __lightingUpdateCounter
        list __lightingUpdateList
        int[:] __lightingUpdateList3
        World __worldObj
        int __worldWidth
        int __worldLength
        int __worldHeight
        list __updateChunks
        list __blockLightUpdateChunks
        list __skylightUpdateChunks
        object __metadataChunkBlock
        int __prevSkylight
        int __skylightSubtracted

    cdef updateSkylight(self, int x0, int y0, int x1, int y1)
    cdef updateDaylightCycle(self, int lightSubtracted)
    cdef updateBlockLight(self, int x0, int y0, int z0, int x1, int y1, int z1)
    cdef __updateCounter(self, int x0, int y0, int z0, int x1, int y1, int z1)
    cdef updateLight(self)
