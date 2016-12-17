# ProtoCamera
=================================================================
This project mimics the video-recording functionality found in the video Q&A platform called [Whale](https://askwhale.com/). 

This project uses the MVVM paradigm to abstract the raw video file data storage from the UI portion of the main video-recording controller. It also incorporates a data-binding mechanism through [Bond](https://github.com/ReactiveKit/Bond) thereby eliminating the need for any type of KVO (or related) implementation to connect the View and ViewModel. 

Though this camera is in working order there are still more projected tasks to be completed... in due time.

To do
======
1. Fix up some of the wonky View-ViewModel connections with the recoding UIControls
2. Fix the weird flickering on playback when toggling between rear and front camera while recording
3. Add a better playback interface - add a scrubber for seeking to different times during the video 
4. Where are the tests man?
