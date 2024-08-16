# cython: language_level=3

from mc.net.minecraft.game.level.path.Path import Path
from mc.net.minecraft.game.level.path.PathPoint import PathPoint
from mc.net.minecraft.game.level.path.PathEntity import PathEntity
from mc.net.minecraft.game.level.material.Material import Material
from mc.net.minecraft.game.level.World cimport World
from mc.net.minecraft.game.entity.Entity cimport Entity

cdef class Pathfinder:

    def __init__(self, World world):
        self.__worldMap = world
        self.__path = Path()
        self.__pointMap = {}
        self.__pathOptions = [None] * 32

    def createEntityPathTo(self, Entity fromEntity, Entity toEntity, float distance):
        return self.__addToPath(fromEntity, toEntity.posX, toEntity.boundingBox.minY,
                                toEntity.posZ, 16.0)

    def createEntityPath(self, Entity entity, int x, int y, int z, float distance):
        return self.__addToPath(entity, x + 0.5, y + 0.5, z + 0.5, 16.0)

    cdef __addToPath(self, Entity entity, float x, float y, float z, float distance):
        cdef int directions, i
        cdef char yOffset
        cdef float d

        self.__path.clearPath()
        self.__pointMap.clear()
        entityPath = self.__openPoint(
            <int>entity.boundingBox.minX, <int>entity.boundingBox.minY,
            <int>entity.boundingBox.minZ
        )
        targetPath = self.__openPoint(<int>(x - entity.width / 2.0), <int>y,
                                      <int>(z - entity.width / 2.0))
        sizePoint = PathPoint(<int>(entity.width + 1.0), <int>(entity.height + 1.0),
                              <int>(entity.width + 1.0))
        entityPath.totalPathDistance = 0.0
        entityPath.distanceToNext = entityPath.distanceTo(targetPath)
        entityPath.distanceToTarget = entityPath.distanceToNext
        self.__path.clearPath()
        self.__path.addPoint(entityPath)
        fartherPoint = entityPath
        while True:
            if self.__path.isPathEmpty():
                if fartherPoint == entityPath:
                    return None
                else:
                    return Pathfinder.__createEntityPath(fartherPoint)

            nextPoint = self.__path.dequeue()
            if nextPoint.hash == targetPath.hash:
                return Pathfinder.__createEntityPath(targetPath)

            if nextPoint.distanceTo(targetPath) < fartherPoint.distanceTo(targetPath):
                fartherPoint = nextPoint

            nextPoint.isFirst = True
            directions = 0
            yOffset = 0
            if self.__getVerticalOffset(nextPoint.xCoord, nextPoint.yCoord + 1,
                                        nextPoint.zCoord, sizePoint):
                yOffset = 1

            south = self.__getSafePoint(entity, nextPoint.xCoord, nextPoint.yCoord,
                                        nextPoint.zCoord + 1, sizePoint, yOffset)
            west = self.__getSafePoint(entity, nextPoint.xCoord - 1, nextPoint.yCoord,
                                        nextPoint.zCoord, sizePoint, yOffset)
            east = self.__getSafePoint(entity, nextPoint.xCoord + 1, nextPoint.yCoord,
                                        nextPoint.zCoord, sizePoint, yOffset)
            north = self.__getSafePoint(entity, nextPoint.xCoord, nextPoint.yCoord,
                                        nextPoint.zCoord - 1, sizePoint, yOffset)
            if south and not south.isFirst and south.distanceTo(targetPath) < distance:
                directions += 1
                self.__pathOptions[0] = south
            if west and not west.isFirst and west.distanceTo(targetPath) < distance:
                self.__pathOptions[directions] = west
                directions += 1
            if east and not east.isFirst and east.distanceTo(targetPath) < distance:
                self.__pathOptions[directions] = east
                directions += 1
            if north and not north.isFirst and north.distanceTo(targetPath) < distance:
                self.__pathOptions[directions] = north
                directions += 1

            for i in range(directions):
                point = self.__pathOptions[i]
                d = nextPoint.totalPathDistance + nextPoint.distanceTo(point)
                if not point.isAssigned() or d < point.totalPathDistance:
                    point.previous = nextPoint
                    point.totalPathDistance = d
                    point.distanceToNext = point.distanceTo(targetPath)
                    if point.isAssigned():
                        self.__path.changeDistance(
                            point, point.totalPathDistance + point.distanceToNext
                        )
                    else:
                        point.distanceToTarget = point.totalPathDistance + \
                                                 point.distanceToNext
                        self.__path.addPoint(point)

    cdef __getSafePoint(self, Entity entity, int x, int y, int z,
                        sizePoint, int yOffset):
        cdef int i
        point = None
        if self.__getVerticalOffset(x, y, z, sizePoint):
            point = self.__openPoint(x, y, z)
        if not point and self.__getVerticalOffset(x, y + yOffset, z, sizePoint):
            point = self.__openPoint(x, y + yOffset, z)

        if point:
            i = 0
            while y > 0 and self.__getVerticalOffset(x, y - 1, z, sizePoint):
                i += 1
                if i >= 4:
                    return None

                y -= 1
                point = self.__openPoint(x, y, z)

        return point

    cdef __openPoint(self, int x, int y, int z):
        cdef int pos = x | y << 10 | z << 20
        point = self.__pointMap.get(pos)
        if not point:
            point = PathPoint(x, y, z)
            self.__pointMap[pos] = point

        return point

    cdef bint __getVerticalOffset(self, int x, int y, int z, sizePoint):
        cdef int xx, yy, zz
        for xx in range(x, x + sizePoint.xCoord):
            if xx < 0 or xx >= self.__worldMap.width:
                return False

            for yy in range(y, y + sizePoint.yCoord):
                if yy < 0 or yy >= self.__worldMap.height:
                    return False

                zz = z
                while zz < z + sizePoint.zCoord:
                    if zz >= 0 and zz < self.__worldMap.length:
                        material = self.__worldMap.getBlockMaterial(x, y, z)
                        if material.getIsSolid():
                            return False

                        if material != Material.water and material != Material.lava:
                            zz += 1
                            continue

                        return False

                    return False

        return True

    @staticmethod
    cdef __createEntityPath(point):
        cdef int size = 1
        prev = point
        while prev.previous:
            size += 1
            prev = prev.previous

        points = [None] * size
        prev = point
        size -= 1
        points[size] = point
        while prev.previous:
            prev = prev.previous
            size -= 1
            points[size] = prev

        return PathEntity(points)
