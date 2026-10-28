# Luminosys
A free light meter app for iOS

The app is available on the App Store, albeit with ads: https://apps.apple.com/us/app/luminosys-light-meter/id6476405389

# Architecture
Luminosys uses the LuxProcessor class, which is the AVCaptureVideoDataOutputSampleBufferDelegate, to recieve frames from the camera. The LuxProcessor class then uses the Exif data combined with an equation to return a light level in lux based on the Exif data. The calibration was determined by running a regression between values from the Exif data and other light meter apps as well as ambient light sensors for lower values.
