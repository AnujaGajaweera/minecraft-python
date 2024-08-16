from mc.net.minecraft.game.level.path.PathPoint import PathPoint

class Path:

    def __init__(self):
        self.__pathPoints = [None] * 1024
        self.__count = 0

    def addPoint(self, point):
        if point.index >= 0:
            raise Exception('OW KNOWS!')
        elif self.__count == len(self.__pathPoints):
            points = [None] * (self.__count << 1)
            points[:] = self.__pathPoints[:self.__count]
            self.__pathPoints = points

        self.__pathPoints[self.__count] = point
        point.index = self.__count
        self.__sortBack(self.__count)
        self.__count += 1
        return point

    def clearPath(self):
        self.__count = 0

    def dequeue(self):
        point = self.__pathPoints[0]
        self.__count -= 1
        self.__pathPoints[0] = self.__pathPoints[self.__count]
        self.__pathPoints[self.__count] = None
        if self.__count > 0:
            self.__sortForward(0)

        point.index = -1
        return point

    def changeDistance(self, point, distance):
        prevDistance = point.distanceToTarget
        point.distanceToTarget = distance
        if distance < prevDistance:
            self.__sortBack(point.index)
        else:
            self.__sortForward(point.index)

    def __sortBack(self, index):
        point = self.__pathPoints[index]
        while index > 0:
            idx = index - 1 >> 1
            if point.distanceToTarget >= self.__pathPoints[idx].distanceToTarget:
                break

            self.__pathPoints[index] = self.__pathPoints[idx]
            self.__pathPoints[idx].index = index
            index = idx

        self.__pathPoints[index] = point
        point.index = index

    def __sortForward(self, index):
        point = self.__pathPoints[index]
        while True:
            idx = 1 + (index << 1)
            nextIdx = idx + 1
            if idx >= self.__count:
                break

            pnt = self.__pathPoints[idx]
            nextPoint = None
            distance = float('inf')
            if nextIdx < self.__count:
                nextPoint = self.__pathPoints[nextIdx]
                distance = nextPoint.distanceToTarget

            if pnt.distanceToTarget < distance:
                if pnt.distanceToTarget >= point.distanceToTarget:
                    break

                self.__pathPoints[index] = pnt
                pnt.index = index
                index = idx
            else:
                if distance >= point.distanceToTarget:
                    break

                self.__pathPoints[index] = nextPoint
                nextPoint.index = index
                index = nextIdx

        self.__pathPoints[index] = point
        point.index = index

    def isPathEmpty(self):
        return self.__count == 0
