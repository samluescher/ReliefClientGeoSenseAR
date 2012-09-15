#pragma once

#include "ofMain.h"
#include "TargetConditionals.h"

#if (TARGET_OS_IPHONE)
#include "ofxQCAR.h"
#include "ofxQCAR_Utils.h"
#define USE_QCAR 1
#endif

#include "ofxiPhone.h"
#include "ofxiPhoneExtras.h"
#include "MapFeature.h"
#include "ofxJSONElement.h"
#include "ReliefClientBase.h"


class testApp : public ReliefClientBase{
	
public:
    void setup();
    void update();
    void draw();
    void exit();
	
    void touchDown(ofTouchEventArgs & touch);
    void touchMoved(ofTouchEventArgs & touch);
    void touchUp(ofTouchEventArgs & touch);
    void touchDoubleTap(ofTouchEventArgs & touch);
    void touchCancelled(ofTouchEventArgs & touch);
    
    void lostFocus();
    void gotFocus();
    void gotMemoryWarning();
    void deviceOrientationChanged(int newOrientation);
    
    ofVboMesh terrainVboMesh;
    ofImage heightMap, terrainTex, terrainTexAlpha, heightMapDownsampled;
    ofVec2f terrainSW, terrainNE, terrainCenterOffset;
    ofVec3f terrainToHeightMapScale;
    ofImage terrainCrop, heightMapCrop, heightMapCropResampled;
    ofVec2f normalizedMapCenter, normalizedReliefSize;
    
    std::vector<MapFeature*> mapFeatures;
    ofVboMesh mapFeaturesMesh;
    void urlResponse(ofHttpResponse & response);
    void addItemsFromJSONString(string jsonStr);
    ofMesh getMeshFromFeatures(std::vector<MapFeature*> mapFeatures);
    int numLoading;
    void loadFeaturesFromURL(string url);
    void loadFeaturesFromFile(string filePath);
    float gridSize;
    
    ofLight light;
    
    ofVec2f touchPoint;
    int deviceOrientation;
    
    float terrainUnitToCameraUnit, reliefUnitToCameraUnit;
    bool calibrationMode;
    float timeSinceLastDoubleTap;
    ofVec3f reliefToMarkerOffset;
    ofVec2f terrainExtents;
    
    ofMatrix4x4 modelViewMatrix, projectionMatrix;
    int noMarkerSince;
    
    ofVec3f mapCenter, newMapCenter;
    ofEasyCam cam;
    
    void drawIdentity();
    void drawTerrain(bool transparent);
    void drawGrid(ofVec2f sw, ofVec2f ne, int subdivisionsX, int subdivisionsY, ofColor line);
    void drawGrid(ofVec2f sw, ofVec2f ne, int subdivisionsX, int subdivisionsY, ofColor line, ofColor background);
    void drawReliefGrid();
    void drawTerrainGrid();
    void drawMapFeatures();
    void drawGUI();
    void updateVisibleMap();
    
    bool drawDebugEnabled;
    
    void reliefMessageReceived(ofxOscMessage m);
    void updateRelief();
};

