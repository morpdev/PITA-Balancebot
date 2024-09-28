#include <Simple_MPU6050.h>

#define MPU6050_ADDRESS_AD0_LOW  0x68
#define MPU6050_ADDRESS_AD0_HIGH 0x69
#define MPU6050_DEFAULT_ADDRESS  0x68
#define ENA 6
#define IN1 7
#define IN2 8
#define ENB 11
#define IN3 12
#define IN4 13

#define OFFSETS -2672, 60, 1458, 85, -81, 160
#define IDLE_SETPOINT 0.6

#define READ_DELAY 1

#define MOTOR_ERROR_CORRECTION 15

#define spamtimer(t) for (static uint32_t SpamTimer; (uint32_t)(millis() - SpamTimer) >= (t); SpamTimer = millis())
#define printfloatx(Name,Variable,Spaces,Precision,EndTxt) print(Name); {char S[(Spaces + Precision + 3)];Serial.print(F(" ")); Serial.print(dtostrf((float)Variable,Spaces,Precision ,S));}Serial.print(EndTxt);

Simple_MPU6050 mpu;
ENABLE_MPU_OVERFLOW_PROTECTION();

// PID:
unsigned long currentTime = 0, previousTime = 0, sampleTime = 0;
double PID_setPoint = IDLE_SETPOINT, PID_error = 0, PID_previousError = 0, PID_errorSum = 0, PID_output = 0;
double PID_Kp = 72, PID_Ki = 235, PID_Kd = 3.85;

char bluetoothData;
unsigned long bluetoothOutputTime = 0;
bool isMoving = false;
unsigned long moveTime = 0;
double steeringAngle = 0;

bool isBotFallen = false;

void readMPUData(int16_t *gyro, int16_t *accel, int32_t *quat, uint32_t *timestamp) 
{
	Quaternion q;
	VectorFloat gravity;
	float ypr[3] = {0, 0, 0};
	float xyz[3] = {0, 0, 0};

	spamtimer(READ_DELAY)
	{
		currentTime = millis();
		sampleTime = currentTime - previousTime;
		previousTime = currentTime;

		mpu.GetQuaternion(&q, quat);
		mpu.GetGravity(&gravity, &q);
		mpu.GetYawPitchRoll(ypr, &q, &gravity);
		mpu.ConvertToDegrees(ypr, xyz);
		
		//Serial.println(xyz[0]);

		if(xyz[1] < 35 && xyz[1] > -35)
		{
			if(isBotFallen)
			{
				delay(2000);
				isBotFallen = false;
			}

			PID_error  = PID_setPoint - xyz[1];
			PID_errorSum += PID_error * sampleTime / 1000.0;
			PID_output = (PID_Kp * PID_error) + (PID_Ki * PID_errorSum) + (PID_Kd * (PID_error - PID_previousError) * 1000 / ((double)sampleTime));

			if (xyz[1] < 0.2 && xyz[1] > -0.2)
			{
				PID_errorSum = 0;
				PID_output = 0;
			}

			setMotorSpeed((int)(PID_output - ((xyz[0] + steeringAngle) * MOTOR_ERROR_CORRECTION)), (int)(PID_output + ((xyz[0] + steeringAngle) * MOTOR_ERROR_CORRECTION)));

			PID_previousError = PID_error;
		}
		else if(!isBotFallen)
		{
			isBotFallen = true;
			PID_errorSum = 0;
			PID_output = 0;
			setMotorSpeed(0, 0);
		}
	}
}

void setMotorSpeed(int rightMotorSpeed, int leftMotorSpeed)
{
	rightMotorSpeed = constrain(rightMotorSpeed, -255, 255);
	leftMotorSpeed = constrain(leftMotorSpeed, -255, 255);

	if(rightMotorSpeed >= 0)
	{
		analogWrite(ENA, rightMotorSpeed);
		digitalWrite(IN1, HIGH);
		digitalWrite(IN2, LOW);
	}
	else
	{
		analogWrite(ENA, -rightMotorSpeed);
		digitalWrite(IN1, LOW);
		digitalWrite(IN2, HIGH);
	}

	if(leftMotorSpeed >= 0)
	{
		analogWrite(ENB, leftMotorSpeed);
		digitalWrite(IN3, LOW);
		digitalWrite(IN4, HIGH);
	}
	else
	{
		analogWrite(ENB, -leftMotorSpeed);
		digitalWrite(IN3, HIGH);
		digitalWrite(IN4, LOW);
	}
}

void setup()
{
	Serial.begin(9600);
	
	#if I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE
		Wire.begin();
		Wire.setClock(400000);
	#elif I2CDEV_IMPLEMENTATION == I2CDEV_BUILTIN_FASTWIRE
		Fastwire::setup(400, true);
	#endif

	#ifdef OFFSETS
		mpu.SetAddress(MPU6050_ADDRESS_AD0_LOW).load_DMP_Image(OFFSETS);
	#else
		mpu.SetAddress(MPU6050_ADDRESS_AD0_LOW).CalibrateMPU().load_DMP_Image();
	#endif

	mpu.on_FIFO(readMPUData);
}

void loop()
{
	mpu.dmp_read_fifo();
	
	while(Serial.available() > 0)
	{
		bluetoothData = Serial.read();
	}

  if(millis() - bluetoothOutputTime > 1000)
  {
    Serial.print("S" + String(PID_error) + "F");
    bluetoothOutputTime = millis();
  }
  
	if(bluetoothData == '1')
	{
		isMoving = true;
		moveTime = millis();
		PID_setPoint = IDLE_SETPOINT + 2.4;
		bluetoothData = 'X';
	}
	else if(bluetoothData == '2')
	{
		isMoving = true;
		moveTime = millis();
		PID_setPoint = IDLE_SETPOINT - 2.4;
		bluetoothData = 'X';
	}
	else if(bluetoothData == '3')
	{
		steeringAngle -= 15;
		if(steeringAngle <= -180)
			steeringAngle = 180;
		bluetoothData = 'X';
	}
	else if(bluetoothData == '4')
	{
		steeringAngle += 15;
		if(steeringAngle >= 180)
			steeringAngle = -180;
		bluetoothData = 'X';
	}
	
	if(isMoving && millis() - moveTime > 1250)
	{
		isMoving = false;
		PID_setPoint = IDLE_SETPOINT;
	}
}
