#pragma once

#include "ofMain.h"
#include "TargetConditionals.h"

#if (TARGET_OS_IPHONE)
#include "ofxQCAR.h"
#include "ofxQCAR_Utils.h"
#define USE_QCAR true
#else
#define USE_QCAR false
#endif

#include "ofxiPhone.h"
#include "ofxiPhoneExtras.h"
#include "MapFeature.h"
#include "ofxJSONElement.h"
#include "ReliefClientBase.h"
#include "ofxOsc.h"

#include "ofPinchGestureRecognizer.h"
#include "ofxUI.h"

#define OVERHEAD_HOST "18.85.58.59"

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
    ofImage terrainTex, terrainTexAlpha, heightMap, terrainCrop, sendMap, featureMap, featureMapCrop, featureHeightMap;
    ofVec2f terrainSW, terrainNE, terrainCenterOffset;
    ofVec3f terrainToHeightMapScale;
    float sendMapResampledValues[RELIEF_SIZE_X * RELIEF_SIZE_Y];
    ofVec2f normalizedMapCenter, normalizedReliefSize;
    float terrainPeakHeight, featureHeight;
    ofVec3f surfaceAt(ofVec2f pos);
    
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
    
    float terrainUnitToCameraUnit, reliefUnitToCameraUnit, reliefUnitToTerrainUnit;
    bool calibrationMode, zoomMode;
    float timeSinceLastDoubleTap;
    ofVec3f reliefToMarkerOffset;
    ofVec2f terrainExtents;
    
    ofMatrix4x4 modelViewMatrix, projectionMatrix;
    int noMarkerSince;
    
    ofVec3f mapCenter, newMapCenter;
    ofCamera cam;
    
    void drawIdentity();
    void drawTerrain(bool transparent, bool wireframe);
    void drawGrid(ofVec2f sw, ofVec2f ne, int subdivisionsX, int subdivisionsY, ofColor line);
    void drawGrid(ofVec2f sw, ofVec2f ne, int subdivisionsX, int subdivisionsY, ofColor line, ofColor background);
    void drawReliefGrid();
    void drawTerrainGrid();
    void drawMapFeatures();
    void drawGUI();
    void updateVisibleMap();
    
    bool drawTerrainEnabled, drawTerrainGridEnabled, drawDebugEnabled, drawMapFeaturesEnabled, drawMiniMapEnabled, drawWaterEnabled, tetherWaterEnabled;
    
    void reliefMessageReceived(ofxOscMessage m);
    void updateRelief();
    int reliefSendMode;
        
    
    ofPinchGestureRecognizer *pinchRecognizer;
    void handlePinch(ofPinchEventArgs &e);
     

	ofxUICanvas *calibrationGUI, *layersGUI;
    void guiEvent(ofxUIEventArgs &e);
	
    ofxOscSender overheadSender;
};

