#@ int(label="Size of tiles in pixels:") tileSize
#@ float (label="Minimum tile size (as a fraction of desired tile size:", style="slider", value = 0.2, min=0, max=1, stepSize=0.1) minSize
#@ File (label = "Output directory", style = "directory") path

// Divide_into_Tiles_bySize.ijm
// ImageJ/Fiji macro by Theresa Swayne, Columbia University, 2021-2023
// Grid code based on BIOP_VSI_reader by Olivier Burri & Romain Guiet, EPFL BIOP 2014-2018
// Divides an image or selection on an image into square tiles of the specified size
// If the image size is not a mulitple of the tile size, 
//    smaller tiles will be created down to a threshold fraction of the tile size, specified by the user 
// How to use: 
//     Open an image and run the macro.
//	   
//	   Output: A set of tile images and the ROI set saved in the user-designated folder.

// Caveats: 
// Image names should not have periods except before the file extension, or else the output filename will be truncated

// ---- Setup ----

roiManager("reset");

// get image info
id = getImageID();
title = getTitle();
dotIndex = indexOf(title, ".");
basename = substring(title, 0, dotIndex);

// ---- Run the functions ----

setBatchMode(true); // greatly increases speed and prevents lost tiles
makeGrid(tileSize, minSize, basename, path);
cropAndSave(id, basename, path);
print("Saving to",path);
setBatchMode(false);

// ---- Functions ----

// helper function for how many tiles to make in a row or column
function ceiling(value, tolerance) {
	// finds the ceiling (smallest integer larger than the value), EXCEPT
	//  if this would result in a tile smaller than the tolerance set by the user
	//     (fraction of tile size below which an edge tile is not created)
	// tolerance = 0.2; 
	if (value - round(value) > tolerance) {
		return round(value)+1;
	} else {
		return round(value);
	}
}

// helper function for adding ROIs to the ROI manager, with the right name
function addRoi() {
	image = getTitle();
	roinum = roiManager("Count");
	Roi.setName(image+" ROI #"+(roinum+1));
	roiManager("Add");
}


/*
 * Creates a regular non-overlapping grid around the user's selection in tiles of selectedSize
 * and saves the ROI set
 */
function makeGrid(selectedSize, minimumSize, imageName, savePath) {
	
	//Make grid based on selection or whole image
	getSelectionBounds(x, y, width, height);
	
	// Set Color
	color = "red";

	// Calculate how many boxes we will need based on the user-selected size 
	// --  note that thin edges will not be converted, based on tolerance in ceiling function
	nBoxesX = ceiling(width/selectedSize, minimumSize);
	nBoxesY = ceiling(height/selectedSize, minimumSize);
	
	run("Remove Overlay");
	roiManager("Reset");

	for(j=0; j< nBoxesY; j++) {
		for(i=0; i< nBoxesX; i++) {
			makeRectangle(x+i*selectedSize, y+j*selectedSize, selectedSize,selectedSize);
			addRoi();
		}
	}

	run("Select None");
	roiManager("save", savePath+File.separator+imageName+"_ROIs.zip");
}

// function to loop through ROIs, create corresponding cropped images, and save
function cropAndSave(id, basename, savePath) {

	// make sure nothing is selected to begin with
	roiManager("Deselect");
	run("Select None");
	
	numROIs = roiManager("count");
	// calculate how much to pad the ROI numbers
	digits = 1 + Math.ceil((log(numROIs)/log(10)));
	for(roiIndex=0; roiIndex < numROIs; roiIndex++) // loop through ROIs and save
		{ 
		selectImage(id);
		roiNum = roiIndex + 1; // image names starts with 1 like the ROI labels
		roiNumPad = IJ.pad(roiNum, digits);
		cropName = basename+"_tile_"+roiNumPad;
		roiManager("Select", roiIndex);  // ROI indices start with 0
		run("Duplicate...", "title=&cropName duplicate"); // creates the cropped image
		selectWindow(cropName);
		saveAs("tiff", savePath+File.separator+getTitle);
		close();
		}	
	run("Select None");
}

