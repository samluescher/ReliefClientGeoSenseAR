#include "testApp.h"
#include "ImageMesh.h"

#define NO_MARKER_TOLERANCE_FRAMES 10
#define FEATURE_HEIGHT .25f
#define GRID_SUBDIVISIONS 10
#define MAX_VAL 500.0f // for normalizing val -- this will come from db later
#define WATER_COLOR ofColor(0, 100, 120)

#define fukushima ofVec2f(141.033247, 37.425252)

#define RELIEF_SIZE_X 12
#define RELIEF_SIZE_Y 12

void copyImageWithAlphaScale(ofImage &from, ofImage &to, float alphaScale) {
    for (int y = 0; y < from.height; y++) {
        for (int x = 0; x < from.height; x++) {
            ofColor c = from.getColor(x, y);
            c.a *= alphaScale;
            to.setColor(x, y, c);
        }
    }
}

//--------------------------------------------------------------
void testApp::setup() {
#if (USE_QCAR)
    ofLog() << "Initializing QCAR";
    [ofxQCAR_Utils getInstance].targetType = TYPE_FRAMEMARKERS;
    ofxQCAR * qcar = ofxQCAR::getInstance();
    qcar->autoFocusOn();
    qcar->setup();
    noMarkerSince = -NO_MARKER_TOLERANCE_FRAMES;
#endif
    
    ofLog() << "Loading maps";
	heightMap.loadImage("maps/heightmap.ASTGTM2_128,28,149,45-14400.png");
    heightMapDownsampled.loadImage("maps/heightmap.ASTGTM2_128,28,149,45-1600.png");
	terrainTex.loadImage("maps/srtm.ASTGTM2_128,28,149,45-14400.png");
    terrainTexAlpha.allocate(terrainTex.width, terrainTex.height, OF_IMAGE_COLOR_ALPHA);
    copyImageWithAlphaScale(terrainTex, terrainTexAlpha, .8);
    terrainTexAlpha.reloadTexture();
    
    terrainSW = ofVec2f(128, 28);
    terrainNE = ofVec2f(150, 46);
    terrainExtents = ofVec2f(terrainNE.x - terrainSW.x, terrainNE.y - terrainSW.y);
    ofLog() << "terrainExtents: " << terrainExtents.x << "," << terrainExtents.y;
    ofVec2f center = terrainSW + terrainExtents / 2;
    terrainToHeightMapScale = ofVec3f(terrainExtents.x / heightMap.width, terrainExtents.y / heightMap.height, 1);
    terrainToHeightMapScale.z = (terrainToHeightMapScale.x + terrainToHeightMapScale.y) / 2;
    float terrainPeakHeight = terrainToHeightMapScale.z * 1500;
    terrainCenterOffset = ofVec3f(center.x, center.y, 0); 
    mapCenter = ofVec3f(141, 37.4, 0); // initially center on Fukushima
    terrainUnitToCameraUnit = 1 / 600.0f;
    
    reliefUnitToCameraUnit = 39.5f;
    
    // offset of physical Relief to physical marker
    reliefToMarkerOffset = ofVec3f(0, /*(RELIEF_SIZE_Y / 2 + 1) * reliefUnitToCameraUnit*/265, 0);
    
    ofEnableNormalizedTexCoords();
    int heightMapSkipPixels = (heightMap.width * heightMap.height) / 1000000 * .8;
	terrainVboMesh = meshFromImage(heightMap, heightMapSkipPixels, terrainPeakHeight);
    
    light.enable();
    light.setPosition(100, 0, 0);
    
    numLoading = 0;
    ofRegisterURLNotification(this);  
    loadFeaturesFromFile("json/safecast.6.json");
    //string url = "http://map.safecast.org/api/mappoints/4ff47bc60aea6a01ec00000f?b=&"+ofToString(terrainSW.x)+"b="+ofToString(terrainSW.y)+"&b="+ofToString(terrainNE.x)+"&b="+ofToString(terrainNE.y)+"&z=6";
    //loadFeaturesFromURL(url);
    
    calibrationMode = drawDebugEnabled = false;
    timeSinceLastDoubleTap = 0;
    
    updateVisibleMap();
}

void testApp::update() 
{    
    reliefUpdate();
#if (USE_QCAR)
    ofxQCAR::getInstance()->update();
#endif
}

//--------------------------------------------------------------

void testApp::drawTerrain(bool transparent) {
    ofPushMatrix();
    ofTranslate(terrainSW + terrainExtents / 2);
    ofScale(terrainToHeightMapScale.x, terrainToHeightMapScale.y, terrainToHeightMapScale.z); 
    ofSetColor(255, 255, 255, 5);
    
    if (transparent) terrainTexAlpha.bind(); else terrainTex.bind();
    terrainVboMesh.draw(); 
    if (transparent) terrainTexAlpha.unbind(); else terrainTex.unbind();
    ofPopMatrix();
}

void testApp::drawMapFeatures() 
{
    glLineWidth(10);
    mapFeaturesMesh.draw();
    
    
    /*
     for(int i = 0; i < mapFeatures.size(); i++) {
     ofPushMatrix();
     
     ofVec3f pos = mapFeatures[i]->getPosition();
     ofTranslate(pos);
     ofScale(mapFeatures[i]->width * .5, mapFeatures[i]->width *.5, mapFeatures[i]->normVal * mapFeatures[i]->height);
     
     ofFill();
     ofSetColor(min(mapFeatures[i]->normVal * 255, 255.0f), 128, 200, 150);
     ofTranslate(0, 0, 0.5);
     ofBox(1);
     
     ofPopMatrix();
     } 
     */
}

void testApp::draw(){
    
#if (USE_QCAR)
    ofxQCAR * qcar = ofxQCAR::getInstance();
    qcar->draw();
    
    if (qcar->hasFoundMarker()) {
        modelViewMatrix = qcar->getProjectionMatrix();
        projectionMatrix = qcar->getModelViewMatrix();
        noMarkerSince = 0;
    }
    
    bool useARMatrix = noMarkerSince > -NO_MARKER_TOLERANCE_FRAMES;
#else
    bool useARMatrix = false;
#endif
    
    
    ofPushView();
    
    if (useARMatrix) {
        glMatrixMode(GL_PROJECTION);
        glLoadMatrixf(modelViewMatrix.getPtr());
        
        glMatrixMode(GL_MODELVIEW );
        glLoadMatrixf(projectionMatrix.getPtr());
    }
    
    ofPushMatrix();
    if (useARMatrix) {
        ofScale(1 / terrainUnitToCameraUnit, 1 / terrainUnitToCameraUnit, 1 / terrainUnitToCameraUnit); 
    }
    
    ofPushMatrix();
    //            ofTranslate(-terrainCenterOffset - (mapCenter - terrainCenterOffset));
    
    ofTranslate(-mapCenter);
    
    ofEnableBlendMode(OF_BLENDMODE_ALPHA);
    
    if (!calibrationMode) {
        
        glEnable(GL_DEPTH_TEST);
        drawTerrain(useARMatrix);
        glDisable(GL_DEPTH_TEST);
        drawMapFeatures();
        
        drawTerrainGrid();
        
        // Fuji
        ofSetColor(0, 255, 0);
        ofSphere(fukushima.x, fukushima.y, 0, .05);
    }
    
    ofDisableBlendMode();
    
    ofPopMatrix();
    if (drawDebugEnabled || calibrationMode) {
        drawIdentity();
    }
    ofPopMatrix();
    
    if (drawDebugEnabled || calibrationMode) {
        drawReliefGrid();
    }
    
    ofPopView();
    
#if (USE_QCAR)
    if (useARMatrix) {
        ofSetColor(255);
        qcar->drawMarkerCenter();
    }
#endif 
    
    if (!calibrationMode) {
        testApp::drawGUI();
    }
}

void testApp::drawGUI() 
{
    ofEnableBlendMode(OF_BLENDMODE_ALPHA);
    switch (deviceOrientation) {
        case OFXIPHONE_ORIENTATION_LANDSCAPE_RIGHT:
        case OFXIPHONE_ORIENTATION_LANDSCAPE_LEFT:
            break;
    }
    glLineWidth(1);
    
    float miniMapW = 350;
    float miniMapUnitsToHeightMapUnits = miniMapW / (float)heightMap.width;
    float miniMapH = miniMapUnitsToHeightMapUnits * heightMap.height;
    ofVec2f p = ofVec2f(ofGetWidth() - miniMapW - 10, 10);
    ofFill();
    ofSetColor(WATER_COLOR);
    ofRect(p, miniMapW, miniMapH);
    ofSetColor(255);
    
    terrainTex.draw(p, miniMapW, miniMapH);
    
    
    ofPushMatrix();
    ofTranslate(p.x, p.y + miniMapH);
    ofScale(miniMapW / terrainExtents.x, -miniMapH / terrainExtents.y);
    ofTranslate(-terrainSW);
    
    ofNoFill();
    
    ofSetColor(200, 200, 200, 100);
    for(int y = terrainSW.y; y < terrainNE.y; y++) {
        for(int x = terrainSW.x; x < terrainNE.x; x++) {
            ofVec3f pos = ofVec3f(x, y);
            ofRect(pos, 1, 1);
        }
    }        
    
    if (drawDebugEnabled) {
        ofFill();
        for(int i = 0; i < mapFeatures.size(); i++) {
            ofSetColor(mapFeatures[i]->color);
            ofVec3f pos = mapFeatures[i]->getPosition();
            ofRect(pos - gridSize / 2, gridSize, gridSize);
        }        
    }
    
    ofNoFill();
    ofSetColor(0, 255, 150, 250);
    ofCircle(mapCenter, .5);
    
    ofPopMatrix();
    
    
    ofPushMatrix();
    ofTranslate(p);
    
    ofNoFill();
    ofSetColor(255, 255, 255, 240);
    
    float marqueeW = normalizedReliefSize.x * miniMapW;
    float marqueeH = normalizedReliefSize.y * miniMapH;
    ofVec2f mapCenterOnMiniMap = normalizedMapCenter * ofVec2f(miniMapW, miniMapH);
    
    ofRect(mapCenterOnMiniMap - ofVec2f(marqueeW / 2, marqueeH / 2), marqueeW, marqueeH);
    ofCircle(mapCenterOnMiniMap, 4);
    ofPopMatrix();
    
    ofSetColor(255);
    int imgH = miniMapW / terrainCrop.width * terrainCrop.height;
    p += ofVec2f(0, miniMapH + 10);
    ofFill();
    ofSetColor(WATER_COLOR);
    ofRect(p, miniMapW, imgH);
    ofSetColor(255);
    terrainCrop.draw(p, miniMapW, imgH);
    
    p += ofVec2f(0, imgH + 10);
    heightMapCrop.draw(p, miniMapW, imgH);
    
    p += ofVec2f(0, imgH + 10);
    heightMapCropResampled.draw(p, miniMapW, imgH);
    
    if (calibrationMode) {
        ofFill();
        ofSetColor(20, 20, 20, 150);
        ofRect(0, 0, ofGetWidth(), ofGetHeight());
    }
    
    ofDisableBlendMode();
    
    string msg = "fps: " + ofToString(ofGetFrameRate(), 2) + ", features: " + ofToString(mapFeatures.size());
    msg += "\nterrain scale: " + ofToString(terrainToHeightMapScale);
    if (false/*numLoading > 0*/) {
        msg += "\nloading data";
    }
    
#if (USE_QCAR)
    ofxQCAR * qcar = ofxQCAR::getInstance();  
    if (qcar->hasFoundMarker()) {
        //msg += "\n" + qcar->getMarkerName();
    }
#endif
    
    if (calibrationMode) {
        msg += "\n---CALIBRATION MODE---";
        msg += "\nreliefUnitToCameraUnit: " + ofToString(reliefUnitToCameraUnit);
        msg += "\nreliefToMarkerOffset: " + ofToString(reliefToMarkerOffset);
    }    
    
    ofVec2f consolePos = ofVec2f(10, 20);
    /*ofSetColor(0);
     ofDrawBitmapString(msg, consolePos.x + 1, consolePos.y + 1);
     ofDrawBitmapString(msg, consolePos.x - 1, consolePos.y - 1);*/
    ofSetColor(255);
	ofDrawBitmapString(msg, consolePos.x, consolePos.y);
}

void testApp::drawGrid(ofVec2f sw, ofVec2f ne, int subdivisionsX, int subdivisionsY, ofColor line, ofColor background) {
    ofFill();
    ofSetColor(background);
    ofRect(sw.x, sw.y, ne.x - sw.x, ne.y - sw.y);
    drawGrid(sw, ne, subdivisionsX, subdivisionsY, line);
}

void testApp::updateVisibleMap()
{
    normalizedMapCenter = ((mapCenter - terrainSW) + reliefToMarkerOffset * terrainUnitToCameraUnit) / terrainExtents;    
    normalizedMapCenter.y = 1 - normalizedMapCenter.y;
    
    ofVec2f reliefToHeightMapScale = ofVec2f(
                                             terrainToHeightMapScale.x / terrainUnitToCameraUnit * reliefUnitToCameraUnit,
                                             terrainToHeightMapScale.y / terrainUnitToCameraUnit * reliefUnitToCameraUnit);
    
    // !! TODO: this is wrong
    normalizedReliefSize = ofVec2f(1 / reliefToHeightMapScale.x * RELIEF_SIZE_X, 1 / reliefToHeightMapScale.y * RELIEF_SIZE_Y);
    
    
    heightMapCrop.allocate(normalizedReliefSize.x * heightMapDownsampled.width, normalizedReliefSize.y * heightMapDownsampled.height, OF_IMAGE_COLOR);
    heightMapCrop.cropFrom(heightMapDownsampled, -heightMapCrop.width / 2 + normalizedMapCenter.x * heightMapDownsampled.width, -heightMapCrop.height / 2 + normalizedMapCenter.y * heightMapDownsampled.height, heightMapCrop.width, heightMapCrop.height);
    
    terrainCrop.allocate(normalizedReliefSize.x * terrainTex.width, normalizedReliefSize.y * terrainTex.height, OF_IMAGE_COLOR);
    terrainCrop.cropFrom(terrainTex, -terrainCrop.width / 2 + normalizedMapCenter.x * terrainTex.width, -terrainCrop.height / 2 + normalizedMapCenter.y * terrainTex.height, terrainCrop.width, terrainCrop.height);
    
    float stepY = heightMapCrop.height / RELIEF_SIZE_Y;
    float stepX = heightMapCrop.width / RELIEF_SIZE_X;
    
    heightMapCropResampled.allocate(stepX * RELIEF_SIZE_X, stepY * RELIEF_SIZE_Y, OF_IMAGE_COLOR);
    
    ofxOscMessage message;
    message.setAddress("/relief/load");
    
    for (int x = RELIEF_SIZE_X - 1; x >= 0; x--) {
        for (int y = 0; y < RELIEF_SIZE_Y; y++) {
            
            int samp = 0;
            int fromX = x * stepX;
            int fromY = y * stepY;
            int toX = fromX + stepX;
            int toY = fromY + stepY;
            
            for (int sy = fromY; sy < toY; sy++) {
                for (int sx = fromX; sx < toX; sx++) {
                    ofColor c = heightMapCrop.getColor(sx, sy);
                    if (c.a > 0) {
                        samp += c.r;
                    }
                }
            }
            
            float avg = samp / (float)(stepX * stepY);
            message.addIntArg(avg / 255 * 127);
            
            ofColor avgColor = ofColor(avg);
            for (int sy = fromY; sy < toY; sy++) {
                for (int sx = fromX; sx < toX; sx++) {
                    heightMapCropResampled.setColor(sx, sy, avgColor);
                }
            }
        }
    }
    
    //reliefMessageSend(message);
    
    heightMapCropResampled.reloadTexture();
}


void testApp::reliefMessageReceived(ofxOscMessage m) {
    
}



void testApp::drawGrid(ofVec2f sw, ofVec2f ne, int subdivisionsX, int subdivisionsY, ofColor line) {
    int index = 0;
    float step = 1 / (subdivisionsX >= 1 ? (float)subdivisionsX : 1);
    for (float x = sw.x; x <= ne.x; x += step) {
        if (index % subdivisionsX == 0) {
            glLineWidth(4);
            ofSetColor(line.r, line.g, line.b, line.a);
        } else {
            glLineWidth(2);
            ofSetColor(line.r, line.g, line.b, line.a / 2);
        }
        ofLine(ofVec3f(x, sw.y, 0), ofVec3f(x, ne.y, 0));
        index++;
    }
    index = 0;
    step = 1 / (subdivisionsY >= 1 ? (float)subdivisionsX : 1);
    for (float y = sw.y; y <= ne.y; y += step) {
        if (index % subdivisionsY == 0) {
            glLineWidth(4);
            ofSetColor(line.r, line.g, line.b, line.a);
        } else {
            glLineWidth(2);
            ofSetColor(line.r, line.g, line.b, line.a / 2);
        }
        ofLine(ofVec3f(sw.x, y, 0), ofVec3f(ne.x, y, 0));
        index++;
    }
    
    ofFill();
    ofSetColor(255, 0, 0);
    ofSphere(terrainSW.x, terrainSW.y, 0, .25);
    
    ofFill();
    ofSetColor(255, 255, 0);
    ofSphere(terrainNE.x, terrainNE.y, 0, .25);
}

void testApp::drawTerrainGrid() {
    drawGrid(terrainSW, terrainNE, GRID_SUBDIVISIONS, GRID_SUBDIVISIONS, ofColor(60, 60, 60, 70));
}

void testApp::drawReliefGrid() {
    ofPushMatrix();
    ofTranslate(reliefToMarkerOffset);
    ofScale(reliefUnitToCameraUnit, reliefUnitToCameraUnit, reliefUnitToCameraUnit);
    float reliefScreenW = RELIEF_SIZE_X;
    float reliefScreenH = RELIEF_SIZE_Y;
    ofEnableBlendMode(OF_BLENDMODE_ALPHA);
    drawGrid(ofVec2f(-reliefScreenW / 2, -reliefScreenH / 2), ofVec2f(reliefScreenW / 2, reliefScreenH / 2), 1, 1, ofColor(200, 200, 200, 200), ofColor(255, 0, 0, 100));
    ofDisableBlendMode();
    ofPopMatrix();
}

void testApp::drawIdentity() {
    glLineWidth(6);
    ofSetColor(255, 0, 0);
    ofLine(ofVec3f(0, 0, 0), ofVec3f(1, 0, 0));
    ofSetColor(0, 255, 0);
    ofLine(ofVec3f(0, 0, 0), ofVec3f(0, 1, 0));
    ofSetColor(0, 0, 255);
    ofLine(ofVec3f(0, 0, 0), ofVec3f(0, 0, 1));
}


ofVec3f lngLatToVec3f(float lng, float lat) {
    return ofVec3f(lng, lat, 0);
}

//Loads json data from a file
void testApp::loadFeaturesFromFile(string filePath) {
	ofFile file(filePath);
	if(!file.exists()){
		ofLogError("The file " + filePath + " is missing");
	}
	ofBuffer buffer(file);
	
	//Read file line by line
    string jsonStr;
	while (!buffer.isLastLine()) {
		jsonStr += buffer.getNextLine();
    }
    
    addItemsFromJSONString(jsonStr);
}

void testApp::loadFeaturesFromURL(string url) {
    cout << url << "\n";
    numLoading++;
    ofLoadURLAsync(url);
}

void testApp::urlResponse(ofHttpResponse & response) {
    numLoading--;
    addItemsFromJSONString(response.data);
}

//Parses a json string into map features
void testApp::addItemsFromJSONString(string jsonStr) {
    ofxJSONElement json;
    int xIndex = 0; int zIndex = 1; 
    if (json.parse(jsonStr)) {
        int size = json["items"].size();
        gridSize = json["gridSize"].asDouble();
        cout << "Items loaded: " << size << endl;
        for (int i = 0; i < size; i++) {
            const Json::Value item = json["items"][i];
            MapFeature *feature = new MapFeature();
            feature->setPosition(lngLatToVec3f(item["loc"][xIndex].asDouble(), item["loc"][zIndex].asDouble()));
            feature->normVal = item["val"]["avg"].asDouble() / MAX_VAL;
            feature->height = min(FEATURE_HEIGHT, FEATURE_HEIGHT * feature->normVal);
            feature->width = gridSize *.9;
            feature->color = ofColor(min(feature->normVal * 255, 255.0f), 128, 200, 150);
            mapFeatures.push_back(feature);
        }
        mapFeaturesMesh = getMeshFromFeatures(mapFeatures);
    } else {
        cout << "Error parsing JSON";
    }
}

ofMesh testApp::getMeshFromFeatures(std::vector<MapFeature*> mapFeatures) {
    ofMesh mesh;
	mesh.setMode(OF_PRIMITIVE_LINES);
    for (int i = 0; i < mapFeatures.size(); i++) {
        
        mesh.addVertex(mapFeatures[i]->getPosition());
        mesh.addColor(mapFeatures[i]->color);
        mesh.addVertex(mapFeatures[i]->getPosition() + ofVec3f(0, 0, mapFeatures[i]->height));
        mesh.addColor(mapFeatures[i]->color);
    }
    return mesh;
}



//--------------------------------------------------------------
void testApp::exit(){
#if (USE_QCAR)
    ofxQCAR::getInstance()->exit();
#endif
}

//--------------------------------------------------------------
void testApp::touchDown(ofTouchEventArgs & touch){
    touchPoint = ofVec2f(touch.x, touch.y);
}

//--------------------------------------------------------------
void testApp::touchMoved(ofTouchEventArgs & touch)
{
    ofVec2f lastTouchPoint = ofVec2f(touch.x, touch.y);
    ofVec2f delta = lastTouchPoint - touchPoint;
    
    switch (deviceOrientation) {
        case OFXIPHONE_ORIENTATION_PORTRAIT:
            delta.x *= -1;
            break;
        case OFXIPHONE_ORIENTATION_UPSIDEDOWN:
            delta.y *= -1;
            break;
        case OFXIPHONE_ORIENTATION_LANDSCAPE_RIGHT:
            delta = ofVec2f(delta.y, delta.x);
            break;
        case OFXIPHONE_ORIENTATION_LANDSCAPE_LEFT:
            delta = ofVec2f(-delta.y, -delta.x);
            break;
    }
    touchPoint = lastTouchPoint;
    
    if (calibrationMode) {
        reliefUnitToCameraUnit += delta.x * .1;
        reliefToMarkerOffset.y += delta.y * .1;
        return;
    }
    
    mapCenter += delta * terrainUnitToCameraUnit;      
    updateVisibleMap();
}

//--------------------------------------------------------------
void testApp::touchUp(ofTouchEventArgs & touch){
}

//--------------------------------------------------------------
void testApp::touchDoubleTap(ofTouchEventArgs & touch) {
    float t = ofGetElapsedTimef();
    cout << t - timeSinceLastDoubleTap << "\n";
    if (true /*t - timeSinceLastDoubleTap < 1*/) {
        updateVisibleMap();
        calibrationMode = !calibrationMode;
    }
    timeSinceLastDoubleTap = t;
}

//--------------------------------------------------------------
void testApp::touchCancelled(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void testApp::lostFocus(){
    
}

//--------------------------------------------------------------
void testApp::gotFocus(){
    
}

//--------------------------------------------------------------
void testApp::gotMemoryWarning(){
    
}

//--------------------------------------------------------------
void testApp::deviceOrientationChanged(int newOrientation){
    deviceOrientation = newOrientation;
    
}

