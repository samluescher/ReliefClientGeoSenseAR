#pragma once

#include "ofMain.h"
#include "ofxEasingFunc.h"
#include "ofEvents.h"
#include "SceneController.h"
#include "ofxQCAR.h"

//--------------------------------------------------------
class QCARController : public SceneController{
	public:
        QCARController();
        void touchDown(ofTouchEventArgs & touch);
        void touchMoved(ofTouchEventArgs & touch);
        void touchUp(ofTouchEventArgs & touch);
        void touchDoubleTap(ofTouchEventArgs & touch);
        void touchCancelled(ofTouchEventArgs & touch);
        void update(ofCamera* camera);

        float easeStartTime;
        ofVec3f previousMousePosition;
        ofVec3f dragVelocity;
};

