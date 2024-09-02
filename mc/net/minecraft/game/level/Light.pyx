# cython: language_level=3

cimport cython

import numpy as np
cimport numpy as np

from mc.net.minecraft.client.render.RenderGlobal cimport RenderGlobal
from mc.net.minecraft.game.level.MetadataChunkBlock import MetadataChunkBlock
from mc.net.minecraft.game.level.World cimport World
from mc.net.minecraft.game.level.block.Block cimport Block
from mc.net.minecraft.game.level.block.Blocks import blocks

cdef class Light:

    def __cinit__(self):
        self.__lightingUpdateCounter = 0
        self.__lightingUpdateList = []
        self.__lightingUpdateList3 = np.zeros(65536, dtype=np.int32)
        self.__updateChunks = []
        self.__blockLightUpdateChunks = []
        self.__skylightUpdateChunks = []
        self.__metadataChunkBlock = None
        self.__prevSkylight = 0
        self.__skylightSubtracted = 0

    def __init__(self, World world):
        self.__worldObj = world
        self.__worldWidth = world.width
        self.__worldLength = world.length
        self.__worldHeight = world.height

    cdef updateSkylight(self, int x0, int y0, int x1, int y1):
        self.__skylightUpdateChunks.append(MetadataChunkBlock(self, x0, y0, 0,
                                                              x1, y1, 1))

    cdef updateDaylightCycle(self, int lightSubtracted):
        lightSubtracted = max(min(lightSubtracted, 15), 0)
        self.__skylightSubtracted = lightSubtracted - self.__worldObj.skylightSubtracted
        if self.__skylightSubtracted != 0:
            self.__prevSkylight = self.__worldObj.skylightSubtracted
            self.__worldObj.skylightSubtracted = lightSubtracted
            self.__metadataChunkBlock = MetadataChunkBlock(
                self, 0, 0, 0, self.__worldObj.width, self.__worldObj.height,
                self.__worldObj.length
            )

    cdef updateBlockLight(self, int x0, int y0, int z0, int x1, int y1, int z1):
        self.__blockLightUpdateChunks.append(MetadataChunkBlock(self, x0, y0, z0,
                                                                x1, y1, z1))

    @cython.boundscheck(False)
    @cython.wraparound(False)
    cdef __updateCounter(self, int x0, int y0, int z0, int x1, int y1, int z1):
        cdef int x, y, z, count
        for y in range(y0, y1):
            for z in range(z0, z1):
                for x in range(x0, x1):
                    self.__lightingUpdateList3[self.__lightingUpdateCounter] = x << 20 | y << 10 | z
                    self.__lightingUpdateCounter += 1
                    if self.__lightingUpdateCounter > \
                       len(self.__lightingUpdateList3) - 32:
                        self.__lightingUpdateCounter -= 1
                        count = self.__lightingUpdateList3[self.__lightingUpdateCounter]
                        self.__lightingUpdateList3[len(self.__lightingUpdateList3) - 1] = self.__lightingUpdateCounter
                        self.__lightingUpdateList.append(self.__lightingUpdateList3)
                        self.__lightingUpdateList3 = np.zeros(len(self.__lightingUpdateList3),
                                                              dtype=np.int32)
                        self.__lightingUpdateCounter = 1
                        self.__lightingUpdateList3[0] = count

    @cython.boundscheck(False)
    @cython.wraparound(False)
    cdef updateLight(self):
        cdef int chunkLimit, maxY, x, z, h, y, i, light, oldDepth, yl0, yl1, count, \
                 br, x0, y0, z0, x1, y1, z1, counter, depth, opacity, newDepth
        cdef RenderGlobal worldAccess

        chunkLimit = 64
        while len(self.__updateChunks) > 0 and chunkLimit > 0:
            chunkLimit -= 1
            chunk = self.__updateChunks.pop(0)
            for worldAccess in self.__worldObj.worldAccesses:
                worldAccess.markBlockRangeNeedsUpdate(
                    chunk.x, chunk.y, chunk.z, chunk.maxX, chunk.maxY, chunk.maxZ
                )

        if self.__metadataChunkBlock:
            chunkLimit = 64
            maxY = self.__metadataChunkBlock.maxY
            for x in range(self.__metadataChunkBlock.x, self.__metadataChunkBlock.maxX):
                if chunkLimit <= 0:
                    self.__metadataChunkBlock.maxY = maxY

                chunkLimit -= 1
                for z in range(self.__metadataChunkBlock.z, self.__metadataChunkBlock.maxZ):
                    h = self.__worldObj.heightMap[x + z * self.__worldWidth] - 1
                    while h > 0 and \
                          self.__worldObj.lightOpacity[self.__worldObj.blocks[(h * \
                              self.__worldLength + z) * self.__worldWidth + x]] < 100:
                        h -= 1

                    for y in range(h + 1, self.__worldHeight):
                        i = (y * self.__worldLength + z) * self.__worldWidth + x
                        if self.__worldObj.lightValue[self.__worldObj.blocks[i]] == 0:
                            light = self.__worldObj.data[i] & 15
                            if light <= self.__prevSkylight:
                                if self.__skylightSubtracted < 0 and light > 0:
                                    self.__worldObj.data[i] -= 1
                                elif self.__skylightSubtracted > 0 and light < 15:
                                    self.__worldObj.data[i] += 1

                    if h < maxY:
                        maxY = y

            self.__lightingUpdateCounter = 0
            self.__lightingUpdateList.clear()

            for x in range(0, self.__worldWidth, 32):
                for z in range(0, self.__worldLength, 32):
                    self.__blockLightUpdateChunks.append(MetadataChunkBlock(
                            self, x, maxY, z, x + 32,
                            self.__worldHeight, z + 32
                        ))
                    self.__updateChunks.append(MetadataChunkBlock(
                            self, x, maxY, z, x + 32,
                            self.__worldHeight, z + 32
                        ))

            for worldAccess in self.__worldObj.worldAccesses:
                worldAccess.updateAllRenderers()

            self.__metadataChunkBlock = None
        else:
            for i in range(200):
                if self.__blockLightUpdateChunks:
                    chunk = self.__blockLightUpdateChunks.pop(0)
                    self.__updateCounter(chunk.x, chunk.y, chunk.z,
                                         chunk.maxX, chunk.maxY, chunk.maxZ)

                if self.__skylightUpdateChunks:
                    chunk = self.__skylightUpdateChunks.pop(0)
                    for x in range(chunk.x, chunk.x + chunk.maxX):
                        for z in range(chunk.y, chunk.y + chunk.maxY):
                            oldDepth = self.__worldObj.heightMap[x + z * self.__worldWidth]
                            y = self.__worldHeight - 1
                            while y > 0 and self.__worldObj.lightOpacity[self.__worldObj.blocks[(y * \
                                  self.__worldLength + z) * self.__worldWidth + x]] == 0:
                                y -= 1

                            self.__worldObj.heightMap[x + z * self.__worldWidth] = y + 1
                            if oldDepth != y:
                                yl0 = oldDepth if oldDepth < y else y
                                yl1 = oldDepth if oldDepth > y else y
                                self.__updateCounter(x, yl0, z, x + 1, yl1, z + 1)

                br = self.__worldObj.skylightSubtracted
                x0 = -999
                x1 = -999
                y0 = -999
                y1 = -999
                z0 = -999
                z1 = -999
                count = 1024
                while count > 0 and (self.__lightingUpdateCounter > 0 or \
                                     len(self.__lightingUpdateList) > 0):
                    count -= 1
                    if self.__lightingUpdateCounter == 0:
                        self.__lightingUpdateList3 = self.__lightingUpdateList.pop()
                        self.__lightingUpdateCounter = self.__lightingUpdateList3[len(self.__lightingUpdateList3) - 1]

                    if self.__lightingUpdateCounter > len(self.__lightingUpdateList3) - 32:
                        self.__lightingUpdateCounter -= 1
                        counter = self.__lightingUpdateList3[self.__lightingUpdateCounter]
                        self.__lightingUpdateList3[len(self.__lightingUpdateList3) - 1] = self.__lightingUpdateCounter
                        self.__lightingUpdateList.append(self.__lightingUpdateList3)
                        self.__lightingUpdateList3 = np.zeros(len(self.__lightingUpdateList3),
                                                              dtype=np.int32)
                        self.__lightingUpdateCounter = 1
                        self.__lightingUpdateList3[0] = counter
                        continue

                    self.__lightingUpdateCounter -= 1
                    counter = self.__lightingUpdateList3[self.__lightingUpdateCounter]
                    x = counter >> 20 & 1023
                    y = counter >> 10 & 1023
                    z = counter & 1023
                    depth = self.__worldObj.heightMap[x + z * self.__worldWidth]
                    depth = br if y >= depth else 0
                    block = self.__worldObj.blocks[(y * self.__worldLength + z) * self.__worldWidth + x]
                    opacity = self.__worldObj.lightOpacity[block]
                    if opacity > 100:
                        depth = 0
                    elif depth < 14:
                        if opacity == 0:
                            opacity = 1

                        newDepth = 0
                        if x > 0:
                            newDepth = (self.__worldObj.data[(y * self.__worldLength + z) * \
                                        self.__worldWidth + (x - 1)] & 15) - opacity
                            if newDepth > depth:
                                depth = newDepth
                        if x < self.__worldWidth - 1:
                            newDepth = (self.__worldObj.data[(y * self.__worldLength + z) * \
                                        self.__worldWidth + x + 1] & 15) - opacity
                            if newDepth > depth:
                                depth = newDepth
                        if y > 0:
                            newDepth = (self.__worldObj.data[((y - 1) * self.__worldLength + z) * \
                                        self.__worldWidth + x] & 15) - opacity
                            if newDepth > depth:
                                depth = newDepth
                        if y < self.__worldHeight - 1:
                            newDepth = (self.__worldObj.data[((y + 1) * self.__worldLength + z) * \
                                        self.__worldWidth + x] & 15) - opacity
                            if newDepth > depth:
                                depth = newDepth
                        if z > 0:
                            newDepth = (self.__worldObj.data[(y * self.__worldLength + (z - 1)) * \
                                        self.__worldWidth + x] & 15) - opacity
                            if newDepth > depth:
                                depth = newDepth
                        if z < self.__worldLength - 1:
                            newDepth = (self.__worldObj.data[(y * self.__worldLength + z + 1) * \
                                        self.__worldWidth + x] & 15) - opacity
                            if newDepth > depth:
                                depth = newDepth

                    depth = max(depth, self.__worldObj.lightValue[block])
                    i = (y * self.__worldLength + z) * self.__worldWidth + x
                    if (self.__worldObj.data[i] & 15) != depth:
                        self.__worldObj.data[i] = <char>((self.__worldObj.data[i] & 240) + depth)
                        if x > 0 and (self.__worldObj.data[(y * self.__worldLength + z) * \
                                      self.__worldWidth + (x - 1)] & 15) != depth - 1:
                            self.__lightingUpdateList3[self.__lightingUpdateCounter] = x - 1 << 20 | y << 10 | z
                            self.__lightingUpdateCounter += 1
                        if x < self.__worldWidth - 1 and \
                           (self.__worldObj.data[(y * self.__worldLength + z) * \
                            self.__worldWidth + x + 1] & 15) != depth - 1:
                            self.__lightingUpdateList3[self.__lightingUpdateCounter] = x + 1 << 20 | y << 10 | z
                            self.__lightingUpdateCounter += 1
                        if y > 0 and (self.__worldObj.data[((y - 1) * self.__worldLength + z) * \
                                      self.__worldWidth + x] & 15) != depth - 1:
                            self.__lightingUpdateList3[self.__lightingUpdateCounter] = x << 20 | y - 1 << 10 | z
                            self.__lightingUpdateCounter += 1
                        if y < self.__worldHeight - 1 and \
                           (self.__worldObj.data[((y + 1) * self.__worldLength + z) * \
                            self.__worldWidth + x] & 15) != depth - 1:
                            self.__lightingUpdateList3[self.__lightingUpdateCounter] = x << 20 | y + 1 << 10 | z
                            self.__lightingUpdateCounter += 1
                        if z > 0 and (self.__worldObj.data[(y * self.__worldLength + \
                                      (z - 1)) * self.__worldWidth + x] & 15) != depth - 1:
                            self.__lightingUpdateList3[self.__lightingUpdateCounter] = x << 20 | y << 10 | z - 1
                            self.__lightingUpdateCounter += 1
                        if z < self.__worldLength - 1 and \
                           (self.__worldObj.data[(y * self.__worldLength + z + 1) * \
                            self.__worldWidth + x] & 15) != depth - 1:
                            self.__lightingUpdateList3[self.__lightingUpdateCounter] = x << 20 | y << 10 | z + 1
                            self.__lightingUpdateCounter += 1

                        if x0 == -999:
                            x0 = x
                            x1 = x
                            y0 = y
                            y1 = y
                            z0 = z
                            z1 = z

                        if x < x0:
                            x0 = x
                        elif x > x1:
                            x1 = x
                        if y > y1:
                            y1 = y
                        elif y < y0:
                            y0 = y
                        if z < z0:
                            z0 = z
                        elif z > z1:
                            z1 = z

                if x0 > -999:
                    self.__updateChunks.append(MetadataChunkBlock(
                            self, x0, y0, z0, x1, y1, z1
                        ))

    def debugSkylightUpdates(self):
        return str(len(self.__blockLightUpdateChunks) + len(self.__skylightUpdateChunks))
