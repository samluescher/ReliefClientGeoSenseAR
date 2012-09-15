#include "QCARController.h"
#include "ofxQCAR_Utils.h"

#define MAP_MOVE_INC 0.1f
#define VELOCITY_DECAY 0.15
#define EASING_TIME 2.0f

QCARController::QCARController() {
    //ofAddListener(ofEvents().keyPressed,this,&QCARController::keyPressed);
    ofRegisterTouchEvents(this);
    [ofxQCAR_Utils getInstance].targetType = TYPE_FRAMEMARKERS;
    ofxQCAR * qcar = ofxQCAR::getInstance();
    qcar->autoFocusOn();
    qcar->setup();
}

//--------------------------------------------------------------
void QCARController::update(ofCamera * camera) {
    ofxQCAR * qcar = ofxQCAR::getInstance();
    qcar->update();
    //camera->set
}

//--------------------------------------------------------------
void QCARController::touchDown(ofTouchEventArgs & touch) {
    
}
void QCARController::touchMoved(ofTouchEventArgs & touch) {
    
}
void QCARController::touchUp(ofTouchEventArgs & touch) {
    
}
void QCARController::touchDoubleTap(ofTouchEventArgs & touch) {
    
}
void QCARController::touchCancelled(ofTouchEventArgs & touch) {
    
}
