list = getList("image.titles");
Version = "v1.03"
if (list.length==0) {
 	  	exit("Garryanalyzer "+Version+" No image file selected. Please Open a Quercus Leaf image and re-launch the Garryanalyzer macro.")
 	  	}
 	  	
	ImageDirectory = getInfo("image.directory");
	ImageName = getTitle();
	ImageNameNoExtension = File.getNameWithoutExtension(ImageName);


// Clear any previous selections or windows
// This is to minimize conflicts and script errors

if (isOpen("Results")) {
    selectWindow("Results");
    run("Close");
}

if (isOpen("Summary")) {
    selectWindow("Summary");
    run("Close");
}

if (isOpen("ROI Manager")) {
    selectWindow("ROI Manager");
    run("Close");
}

print("\\Clear");
run("Clear Results");
run("Clear Results", "exclude");
run("ROI Manager...");
roiManager("reset");

// Define Image

selectWindow(ImageName);

setTool(4); //Set tool to Straight Line
run("Line Width...", "line=50");

waitForUser("Garryanalyzer "+Version+" analysis of "+ImageName+"\n Please confirm the image is horizontal, with petiole on the left.\n Click and drag from base to tip of petiole (Stem), then click OK");
 roiManager("Add");
 
roiManager("select", 0);
roiManager("rename", "Petiole Length");

// Convert the image to 8-bit grayscale
run("8-bit");

// Apply thresholding to segment the object
//setAutoThreshold("Default");
//run("Threshold");

//setAutoThreshold("Default no-reset");
run("Auto Threshold", "method=Huang2");
//setThreshold(0, 254);
run("Convert to Mask");

	roiManager("Select", 0);
	
	Roi.getCoordinates(xpoints, ypoints);
	i = 0;
	Color.set("black");
	ImageHeight = getHeight();
	
	for (i=0; i< ypoints.length; i++) {
	makeRectangle(0, 0, xpoints[i], ImageHeight);
	fill();
	//makeRectangle(0, 0, xpoints[i], ImageHeight);
//	fill();
	}
	
run("Select None");

// Create a mask from the thresholded image
run("Convert to Mask");
//waitForUser("Convert to Mask"); // Diagnostic Step #1
//run("Fill Holes"); // Test new function
// Find the edges of the object

// doWand(getWidth()/2, getHeight()/2);
// run("Make Inverse");
//  setColor(0, 0, 0);
//run("Fill", "slice");

//waitForUser("Island Check"); // Diagnostic Step #2

run("Find Edges");

// Create a highlighted shape
run("Duplicate...", "title=Highlighted_Shape");
run("Multiply...", "value=255");
run("Select None");

// Measure the major and minor axis lengths
//waitForUser("Ellipse Axis Check"); //Diagnostic Step #3
run("3-3-2 RGB");
run("Set Measurements...", "area centroid perimeter fit shape feret's redirect=None decimal=2");
run("Analyze Particles...", "size=0-Infinity show=Masks display clear include summarize");
//waitForUser("Analyze Particles"); // Diagnostic Step #4
Islands = getValue("results.count");

LeafResult = 0;

LeafLargestMajor = 0;
LeafComparisonMajor = 0;

for (i=0; i<Islands; i++) {
  	
  	LeafComparisonMajor = getResult("Major", i);
  	
  	if (LeafComparisonMajor > LeafLargestMajor) {
		LeafResult = i;
		LeafLargestMajor = getResult("Major", i);
  	}
  }

i = LeafResult;

//waitForUser("Island selected ="+i); // Diagnostic Step #6

// Draw best fitting ellipses

getVoxelSize(rescale, height, depth, unit);

majorAxis = getResult("Major", i) / rescale;
minorAxis = getResult("Minor", i) / rescale;

xc = getResult("X", i) / rescale;	// xc = center x, yc = center y
yc = getResult("Y", i) / rescale;

angle = getResult("Angle", i);

print("majorAxis:"+majorAxis+", minorAxis:"+minorAxis);
print("xc:"+xc+", yc:"+xc);

// Draw ellipse
makeOval(xc-(majorAxis/2), yc-(minorAxis/2), majorAxis, minorAxis);
run("Rotate...", "angle=" + (180 - angle));
roiManager("Add"); // ellipses added to ROI Manager
roiManager("select", 1);
roiManager("rename", "Best-Fit Ellipse");
run("Overlay Options...", "stroke=orange width=0 fill=none");
run("Add Selection...");

EllipseX = xc-(majorAxis/2);
EllipseY = yc-(minorAxis/2);

//waitForUser("Created Best-Fit Ellipse"); // Diagnostic Step #7

// Draw axes

a = angle * PI / 180; // convert angle degrees to radians
run("Overlay Options...", "stroke=blue width=0 fill=none");
d = majorAxis;
makeLine(xc+(d/2)*cos(a), yc-(d/2)*sin(a), xc-(d/2)*cos(a), yc+(d/2)*sin(a));
run("Add Selection...");
getLine(x1, y1, x2, y2, lineWidth);
MajorAxisLength = Math.sqrt(Math.pow((x1-x2), 2) + Math.pow((y1-y2), 2));

a = a + PI/2; // rotate angle 90 degrees
run("Overlay Options...", "stroke=red width=0 fill=none");
d = minorAxis;
makeLine(xc+(d/2)*cos(a), yc-(d/2)*sin(a), xc-(d/2)*cos(a), yc+(d/2)*sin(a));
run("Add Selection...");

run("Select None");

// Close the original and highlighted shape images
selectWindow(ImageName);
close();
selectWindow("Highlighted_Shape");
 
close();

//waitForUser("doWand diagnostic Pre"); // Diagnostic Step #7

run("3-3-2 RGB");
 roiManager("Deselect");
 doWand(getWidth()/2, getHeight()/2);
 roiManager("Add");
 
//waitForUser("doWand diagnostic Post"); // Diagnostic Step #8

roiManager("Select", 2);
roiManager("rename", "Blade Outline");
run("To Bounding Box");
 roiManager("Add");
 roiManager("Select", 3);
 roiManager("rename", "Blade Bounds");
 
getSelectionBounds(x, y, width, height);
BladeLength = width;
LeafX = x;
LeafY = (y+(width)/2);
makeLine(x, y+(width)/2, x+width, y+(width)/2);
 roiManager("Add");
  roiManager("Select", 4);
roiManager("rename", "Blade Length");

// After the Petiole Length is measured, we'd have enough information to calculate species type
roiManager("Select", 0);
getLine(x1, y1, x2, y2, lineWidth);
makeLine(x1, y+(width)/2, x2, y+(width)/2);
 roiManager("Add");
   roiManager("Select", 5);
 roiManager("rename", "Petiole Length Flat");
 
PetioleLength = abs(x1-x2);


//waitForUser("Fit Spline diagnostic Pre"); // Diagnostic Step #8

roiManager("Select", 2);
run("Fit Spline");
Roi.getSplineAnchors(xSplineArray, ySplineArray);

SemiMajorAxis = majorAxis/2 ; // Semi-major axis
SemiMinorAxis = minorAxis/2; // Semi-minor axis
Pi = 3.14159265358979323846;
// xc and yc

//waitForUser("doWand diagnostic Post"); // Diagnostic Step #9

// Compile distances into a residual array
residualArray =newArray();
//angle = (180 - angle)

  for (i=0; i<xSplineArray.length; i++) {
//     print(i+":"+xSplineArray[i]+","+ySplineArray[i]);
yActual = ySplineArray[i];
xActual = xSplineArray[i];
	//	print("Iteration: "+i);
        // Calculate normalized direction vector
        deltaX = xActual - xc;
        deltaY = yActual - xc;
        magnitude = Math.sqrt(deltaX * deltaX + deltaY * deltaY);
        unitDeltaX = deltaX / magnitude;
        unitDeltaY = deltaY / magnitude;

 		xClosest = xc + SemiMajorAxis * Math.sin(angle) * unitDeltaX;
    	yClosest = yc + SemiMajorAxis * Math.cos(angle) * unitDeltaY;

        // Parameterize the ellipse's curve
        J = 0;
		numPoints = 300; //xSplineArray.length;
		shortestDistance = 999999999;
		for (J=0; J < numPoints; J++) { // Number of points along the ellipse to calculate distances
            t = (2 * Pi * J) / numPoints; // Vary t from 0 to 2π
			a = -(angle) * PI / 180;
			fNewX = ( SemiMajorAxis * Math.cos(t) * Math.cos(a) ) - ( (SemiMinorAxis)* Math.sin(t) * Math.sin(a) ) + xc ;	
			
			fNewY = ( SemiMajorAxis * Math.cos(t) * Math.sin(a) ) + ( (SemiMinorAxis)* Math.sin(t) * Math.cos(a) ) + yc ;
             
            distance = Math.sqrt(Math.pow(yActual - fNewY, 2) + Math.pow(xActual - fNewX, 2));
			if (i == 0) {
			makePoint(fNewX, fNewY);
			run("Add Selection...");
			}
				

           //
           if (distance < shortestDistance) {
           	shortestDistance = distance;
           	shortestDistanceX = fNewX;
           	shortestDistanceY = fNewY;
         
           	
		//print("Iteration: "+i+", J="+J+" Updated shortestDistance as: "+shortestDistance);
           }

		}
           // Add the distance to the residual array
            residualArray[i] = shortestDistance;
		   // print(i+"::"+xSplineArray[i]+","+ySplineArray[i]+", ShortestDistance="+shortestDistance);   // USED FOR TESTING
		// -------- Visual representation of analysis, un-comment below 2 lines for animation of best-fit ellipse analysis -------------
		//	makeLine(xActual, yActual, shortestDistanceX, shortestDistanceY, 3);
		//	wait(10);
		//---------
  }
  
//waitForUser("Best-Fit Ellipse Post"); // Diagnostic Step #10
  
Array.getStatistics(residualArray, min, max, bestResidualmean, stdDev);
wait(5);
close();
wait(5);
open(ImageName);


//cleaning up

if (isOpen("Results")) {
    selectWindow("Results");
    run("Close");
}

if (isOpen("Summary")) {
    selectWindow("Summary");
    run("Close");
}

// Variables
print("EllipticalScore = ("+bestResidualmean+"/"+majorAxis+")");
print("PetioleBladeLengthRatio = ("+PetioleLength+"/"+BladeLength+")");

print("Elliptical = "+(bestResidualmean/majorAxis));
print("PetioleBladeLengthRatio = "+(PetioleLength/BladeLength));

// Morphology equation
z = -23.99 + (203.60 * (bestResidualmean/majorAxis)) + (132.28 * (PetioleLength/BladeLength));
P = 1/(1+exp(-z));

// Conversion to output
Species = P;
SpeciesR = round(Species);

print(z+","+P);
print(ImageName+","+(bestResidualmean/majorAxis)+","+(PetioleLength/BladeLength));

Dialog.create("Title")

// Morphological identification output
if (SpeciesR == 1) {

print(ImageName+" is a Q. Garryana. Raw score: "+Species);
   } else {
print(ImageName+" is a Q. Robur. Raw score: "+Species);
}

// Morphological identification visual display settings
roiManager("Show All with labels");
roiManager("Select", 1);
Roi.setStrokeColor(255, 0, 0);
roiManager("Select", 2);
Roi.setStrokeColor(0, 0, 255);

// Option to export data to txt file
//saveAs("Text", ImageDirectory+ImageNameNoExtension+".txt");


