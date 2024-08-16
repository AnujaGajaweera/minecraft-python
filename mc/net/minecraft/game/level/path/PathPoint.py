import math

class PathPoint:

    def __init__(self, x, y, z):
        self.xCoord = x
        self.yCoord = y
        self.zCoord = z
        self.hash = x | y << 10 | z << 20
        self.index = -1
        self.totalPathDistance = 0.0
        self.distanceToNext = 0.0
        self.distanceToTarget = 0.0
        self.previous = None
        self.isFirst = False

    def distanceTo(self, point):
        xd = point.xCoord - self.xCoord
        yd = point.yCoord - self.yCoord
        zd = point.zCoord - self.zCoord
        return math.sqrt(xd * xd + yd * yd + zd * zd)

    def __eq__(self, point):
        return point.hash == self.hash

    def __hash__(self):
        return self.hash

    def isAssigned(self):
        return self.index >= 0

    def toString(self):
        return f'{self.xCoord}, {self.yCoord}, {self.zCoord}'
