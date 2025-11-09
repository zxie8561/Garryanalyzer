list = getList("image.titles");
Version = "v1.05.2"
if (list.length==0) {
 	  	exit("Garryanalyzer "+Version+" No image file selected. Please Open a Quercus Leaf image and re-launch the Garryanalyzer macro.")
 	  	}

	ImageDirectory = getInfo("image.directory");
	ImageName = getTitle();
	ImageNameNoExtension = File.getNameWithoutExtension(ImageName);

// Garryanalyzer is a leaf morphological identification ImageJ plugin for quantifying and identifying Quercus garryana and Q. robur leaf images.
// Although specific equation functionality (Subsection Oa) is tuned for Q. garryana and robur leaf differentiation, variables and script workflow is meant to be adaptable for quantification in leaves of other model systems.
// More information and support for Garryanalyzer available on webpage: https://github.com/zxie8561/Garryanalyzer

// A - Clear any previous selections or windows

if (isOpen("Results")) {
    selectWindow("Results");
    run("Close");
}

if (isOpen("Summary")) {
    selectWindow("Summary");
    run("Close");
}

print("\\Clear");
run("Clear Results");
run("Clear Results", "exclude");
run("ROI Manager...");
roiManager("reset");
roiManager("Show None");

selectWindow(ImageName);

setTool(4); // B - Set tool to Straight Line

	run("Line Width...", "line=70");
waitForUser("Garryanalyzer "+Version+" analysis of "+ImageName+"\n Please confirm the image is horizontal, with petiole on the left.\n Click and drag from base to tip of petiole (Stem), then click OK");
roiManager("Add");

roiManager("select", 0);
roiManager("rename", "1 Petiole Length");

// C - Preprocessing - Convert the image to 8-bit grayscale, Threshold, then Convert to Mask
run("8-bit");
run("Auto Threshold", "method=Huang2");
run("Convert to Mask");

// D - Select Petiole/Stem of Leaf, Turn to Black (Mask out of Blade)

	roiManager("Select", 0);
	Roi.getCoordinates(xpoints, ypoints);
	i = 0;
	Color.set("black");
	ImageHeight = getHeight();

	for (i=0; i< ypoints.length; i++) {

	run("Line Width...", "line=70");
	run("Fill", "slice");

	}

run("Select None");

// E - Reconvert to mask, Find Edges
run("Convert to Mask");
run("Find Edges");

// F - Create a highlighted shape, Multiply
run("Duplicate...", "title=Highlighted_Shape");
run("Multiply...", "value=255");
run("Select None");

// G - Measure the major and minor axis lengths (Convert to RGB to show color of measurements)
run("3-3-2 RGB");
run("Set Measurements...", "area centroid perimeter fit shape feret's redirect=None decimal=2");
run("Analyze Particles...", "size=0-Infinity show=Masks display clear include summarize");
Islands = getValue("results.count");

LeafResult = 0;

LeafLargestMajor = 0;
LeafComparisonMajor = 0;

// H - Islands management, Islands refers to other objects in image that survived thresholding. Select largest island (Expected to be Leaf).
for (i=0; i<Islands; i++) {

  	LeafComparisonMajor = getResult("Major", i);

  	if (LeafComparisonMajor > LeafLargestMajor) {
		LeafResult = i;
		LeafLargestMajor = getResult("Major", i);
  	}
  }

i = LeafResult;

// I - Generate the Best-Fit Ellipse

// I a - Calculations for scale
getVoxelSize(rescale, height, depth, unit);

majorAxis = getResult("Major", i) / rescale;
minorAxis = getResult("Minor", i) / rescale;
angle = getResult("Angle", i);

xc = getResult("X", i) / rescale;	// xc = center x, yc = center y
yc = getResult("Y", i) / rescale;

print("xc:"+xc+", yc:"+xc);

//makePoint(xc, yc, "cross");	// Show center point of Ellipse

// I b - Draw ellipse
makeOval(xc-(majorAxis/2), yc-(minorAxis/2), majorAxis, minorAxis);
run("Rotate...", "angle=" + (180 - angle));
	roiManager("Add"); // ellipse is added to ROI Manager

roiManager("select", 1);
roiManager("rename", "2 Best-Fit Ellipsoid");
run("Overlay Options...", "stroke=orange width=0 fill=none");
run("Add Selection...");

EllipseX = xc-(majorAxis/2);
EllipseY = yc-(minorAxis/2);

// I c - Draw axis of Ellipse
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

// Optional, save the highlighted shape with elliptical overlay
//saveAs("JPEG", "ellipsoid.jpg");

// J - Close the original and highlighted shape images
selectWindow(ImageName);
close();
selectWindow("Highlighted_Shape");
close();

// K - Select Leaf Blade via Wand tool
run("3-3-2 RGB");
 doWand(getWidth()/2, getHeight()/2);
 roiManager("Add");

// L - Create additional ROI for Petiole/Blade calculations
roiManager("Select", 2);
roiManager("rename", "3 Blade Outline");
run("To Bounding Box");
 roiManager("Add");
 roiManager("Select", 3);
 roiManager("rename", "4 Blade Bounds");

getSelectionBounds(x, y, width, height);
BladeLength = width;
LeafX = x;
LeafY = (y+(width)/2);
makeLine(x, y+(width)/2, x+width, y+(width)/2);
 roiManager("Add");
  roiManager("Select", 4);
roiManager("rename", "5 Blade Length");

roiManager("Select", 0);
getLine(x1, y1, x2, y2, lineWidth);
makeLine(x1, y+(width)/2, x2, y+(width)/2);
 roiManager("Add");
   roiManager("Select", 5);
 roiManager("rename", "6 Petiole Length Flat");

PetioleLength = abs(x1-x2);

// M - Take our leaf image, fit a 300-point spline to the blade, and use best-fit ellipse to find residuals, avg them, then divide by major length (Elliptical score)
roiManager("Select", 2);
run("Fit Spline");
Roi.getSplineAnchors(xSplineArray, ySplineArray);

SemiMajorAxis = majorAxis/2 ; // Semi-major axis
SemiMinorAxis = minorAxis/2; // Semi-minor axis
Pi = 3.14159265358979323846;
// xc and yc

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

        // Calculate coordinates of the closest point on the ellipse

 		xClosest = xc + SemiMajorAxis * Math.sin(angle) * unitDeltaX;
    	yClosest = yc + SemiMajorAxis * Math.cos(angle) * unitDeltaY;

        // Parameterize the ellipse's curve
        J = 0;
		numPoints = 300; //xSplineArray.length;
		shortestDistance = 999999999;
		for (J=0; J < numPoints; J++) { // Number of points along the ellipse to calculate distances
            t = (2 * Pi * J) / numPoints; // Vary t from 0 to 2

			a = -(angle) * PI / 180;
			fNewX = ( SemiMajorAxis * Math.cos(t) * Math.cos(a) ) - ( (SemiMinorAxis)* Math.sin(t) * Math.sin(a) ) + xc ;

			fNewY = ( SemiMajorAxis * Math.cos(t) * Math.sin(a) ) + ( (SemiMinorAxis)* Math.sin(t) * Math.cos(a) ) + yc ;

            distance = Math.sqrt(Math.pow(yActual - fNewY, 2) + Math.pow(xActual - fNewX, 2));
			if (i == 0) {
			makePoint(fNewX, fNewY);
			run("Add Selection...");
			}

	//	print("Iteration: "+i+", J="+J);

           if (distance < shortestDistance) {
           	shortestDistance = distance;
           	shortestDistanceX = fNewX;
           	shortestDistanceY = fNewY;
           }

		}
           // Add the distance to the residual array
            residualArray[i] = shortestDistance;
			// Elliptical Function in practice. Uncomment
		   // print(i+"::"+xSplineArray[i]+","+ySplineArray[i]+", ShortestDistance="+shortestDistance);   // Used for visual conceptualization and troubleshooting

		// -------- Visual representation of analysis -- Uncomment the below 2 lines to see how Elliptical Function processes. Extends processing time significantly. -------------
		//	makeLine(xActual, yActual, shortestDistanceX, shortestDistanceY, 3);
		//	wait(10);
		//---------------------------------------------------------
  }

Array.getStatistics(residualArray, min, max, bestResidualmean, stdDev);
close();
open(ImageName);

// N - Clean up windows - Close Results, Summary

if (isOpen("Results")) {
    selectWindow("Results");
    run("Close");
}

if (isOpen("Summary")) {
    selectWindow("Summary");
    run("Close");
}

// O - Identification and variable annotation stage. By default this is the streamlined version for Q. Garryana vs Robur, as determined by aggregate data processing for significant variables.

// Variables
print("EllipticalScore = ("+bestResidualmean+"/"+majorAxis+")");
print("PetioleBladeLengthRatio = ("+PetioleLength+"/"+BladeLength+")");

print("Elliptical = "+(bestResidualmean/majorAxis));
print("PetioleBladeLengthRatio = "+(PetioleLength/BladeLength));

// O a - Morphological classification equation. Comment this subsection out until similar identification equation is generated from data.
Species = 5.748116717 * (bestResidualmean/majorAxis) + 2.312502157 * (PetioleLength/BladeLength);
SpeciesR = round(Species);

Dialog.create("Title")
if (SpeciesR == 1) {
print(ImageName+" is a Q. Garryana. Raw score: "+Species);
   } else {
print(ImageName+" is a Q. Robur. Raw score: "+Species);
}

// O b - ROI manager Label annotation stage.
roiManager("Show All with labels");
roiManager("Select", 2);

// O c - Show Results with Blade Outline (particular ROI's additional characteristics)
roiManager("Select", 2);
roiManager("Measure");
Table.rename("Results", "3 Blade Outline");

// P - Data Export. Optional. Data can be exported from ImageJ for later analysis. The line below is set up for individual images, and would need to be combined with like categories.
//saveAs("Text", ImageDirectory+ImageNameNoExtension+".txt");
