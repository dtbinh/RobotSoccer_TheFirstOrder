#!/usr/bin/python
from roboclaw import *
import mlib
import time

p = int(65536 * 4) #262144
i = int(65536 * 2) #131072
d = int(65536 * 6)  #65536
q = 308419

print 'Battery Voltage: ' + str(ReadMainBatteryVoltage(128))
p1,i1,d1,q1,crc = mlib.readMVelocityPID(1)
print "128 M1 P=%.2f" % (p1/65536.0)
print "128 M1 I=%.2f" % (i1/65536.0)
print "128 M1 D=%.2f" % (d1/65536.0)
print "128 M1 QPPS=",q1
p2,i2,d2,q2,crc = mlib.readMVelocityPID(2)
print "128 M2 P=%.2f" % (p2/65536.0)
print "128 M2 I=%.2f" % (i2/65536.0)
print "128 M2 D=%.2f" % (d2/65536.0)
print "128 M2 QPPS=",q2
p3,i3,d3,q3,crc = mlib.readMVelocityPID(3)
print "121 M1 P=%.2f" % (p3/65536.0)
print "129 M1 I=%.2f" % (i3/65536.0)
print "129 M1 D=%.2f" % (d3/65536.0)
print "129 M1 QPPS=",q3

# This function takes multiple samples of the motor speed and then returns the average
def read(motor):
  samples = 4
  result = 0
  for i in range(0, samples):
    sample = 0
    sample = mlib.readSpeedM(motor)[1]
    #print sample
    result = result + sample
  result = result/samples
  return result
  
speedM1Forward=0
speedM1Backward=0
speedM2Forward=0
speedM2Backward=0
speedM3Forward=0
speedM3Backward=0

speed = 48

mlib.stop();

#Forwards
mlib.BackwardM(1,speed); #M1 backward sample 1
mlib.ForwardM(3,speed); #M3 forward sample 1
time.sleep(2)

speedM1Backward=speedM1Backward+read(1)
speedM3Forward=speedM3Forward+read(3)

mlib.stop();
time.sleep(1);

#Backwards
mlib.ForwardM(1,speed); #M1 forward sample 1
mlib.BackwardM(3,speed); #M3 backward sample 1
time.sleep(2)

speedM1Forward=speedM1Forward+read(1)
speedM3Backward=speedM3Backward+read(3)

mlib.stop();
time.sleep(5);

#Left back
mlib.BackwardM(2,speed); #M2 backward sample 2 
mlib.ForwardM(1,speed); #M1 forward sample 1
time.sleep(2)

speedM2Backward=speedM2Backward+read(2)
speedM2Backward=speedM2Backward/2
speedM1Forward=speedM1Forward+read(1)

mlib.stop();
time.sleep(1);

#Left forward
mlib.ForwardM(2,speed); #M2 forward sample 2
mlib.BackwardM(3,speed); #M3 backward sample 1
time.sleep(2)

speedM2Forward=speedM2Forward+read(2)
speedM2Forward=speedM2Forward/2
speedM3Backward=speedM3Backward+read(3)

mlib.stop();
time.sleep(5);

# RightBack
mlib.ForwardM(2,speed); #M2 forward sample 2
mlib.BackwardM(3,speed); #M3 backward sample 2
time.sleep(2)

speedM2Forward=speedM2Forward+read(2)
speedM2Forward=speedM2Forward/2
speedM3Backward=speedM3Backward+read(3)
speedM3Backward=speedM3Backward/2

mlib.stop();
time.sleep(1);

# Right Forward
mlib.BackwardM(2,speed); #M2 backward sample 2
mlib.ForwardM(3,speed); #M3 forward sample 2
time.sleep(2)

speedM2Backward=speedM2Backward+read(2)
speedM2Backward=speedM2Backward/2
speedM3Forward=speedM3Forward+read(3)
speedM3Forward=speedM3Forward/2

mlib.stop();

speedM1Forward=(speedM1Forward*127)/speed
speedM1Backward=(speedM1Backward*127)/speed
speedM2Forward=(speedM2Forward*127)/speed
speedM2Backward=(speedM2Backward*127)/speed
speedM3Forward=(speedM3Forward*127)/speed
speedM3Backward=(speedM3Backward*127)/speed

#print speedM1Forward;
#print speedM1Backward;
#print speedM2Forward;
#print speedM2Backward;
#print speedM3Forward;
#print speedM3Backward;

speedM1 = (speedM1Forward - speedM1Backward)/2
speedM2 = (speedM2Forward - speedM2Backward)/2
speedM3 = (speedM3Forward - speedM3Backward)/2

mlib.setMVelocityPID(1,p,i,d,speedM1)
mlib.setMVelocityPID(2,p,i,d,speedM2)
mlib.setMVelocityPID(3,p,i,d,speedM3)

p1,i1,d1,q1,crc = mlib.readMVelocityPID(1)
print "128 M1 P=%.2f" % (p1/65536.0)
print "128 M1 I=%.2f" % (i1/65536.0)
print "128 M1 D=%.2f" % (d1/65536.0)
print "128 M1 QPPS=",q1
p2,i2,d2,q2,crc = mlib.readMVelocityPID(2)
print "128 M2 P=%.2f" % (p2/65536.0)
print "128 M2 I=%.2f" % (i2/65536.0)
print "128 M2 D=%.2f" % (d2/65536.0)
print "128 M2 QPPS=",q2
p3,i3,d3,q3,crc = mlib.readMVelocityPID(3)
print "121 M1 P=%.2f" % (p3/65536.0)
print "129 M1 I=%.2f" % (i3/65536.0)
print "129 M1 D=%.2f" % (d3/65536.0)
print "129 M1 QPPS=",q3