#pragma once

#include "ofMain.h"
#include "ofxOsc.h"
#include "ofxiPhone.h"

#define RELIEF_HOST "18.189.22.224"
#define RELIEF_PORT 78746

#define RELIEF_SIZE_X 12
#define RELIEF_SIZE_Y 12
#define RELIEF_MAX_VALUE 127

//--------------------------------------------------------
class ReliefClientBase : public ofxiPhoneApp {
    
public:
    ReliefClientBase();
    ~ReliefClientBase();
    void reliefSetup(string host, int port);
    void reliefUpdate();
    
    virtual void reliefMessageReceived(ofxOscMessage m);
    void reliefMessageSend(ofxOscMessage m);
    
    ofxOscSender reliefSender;
    ofxOscReceiver reliefReceiver;
    
    float lastHearbeat;
    
};
