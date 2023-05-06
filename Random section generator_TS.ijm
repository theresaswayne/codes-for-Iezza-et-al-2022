#@ int(label="Width of tiles in pixels:") tileWidth
#@ int(label="Height of tiles in pixels:") tileHeight
#@ int(label="Number of ROIs to generate:") RoisN
#@ double (label="Minimum tile size (as a fraction of desired tile size):", style="slider", value = 0.2, min=0, max=1, stepSize=0.1) minSize
#@ File (label = "Output directory", style = "directory") path
#@ String (label = "Output file name:",choices={"Original name", "ROI number only"}, style="radioButtonHorizontal") outputName

// ImageJ macro to save randomly selected tiles from a large image
// How to use: 
//     Open an image exported with pixel resolution = 0.35 µm and run the script.

// ---- Setup ----

roiManager("reset");
// get image info
id = getImageID();
title = getTitle();
dotIndex = indexOf(title, ".");
basename = substring(title, 0, dotIndex);
// Restore image scale, assuming it was exported at 0.35 µm pixel size
run("Set Scale...", "distance=2.8571 known=1 unit=µm");


// ---- Run the functions ----

setBatchMode(true); // greatly increases speed and prevents lost tiles
makeGrid(tileWidth, tileHeight, minSize, basename, outputName, path);
selectAndSave(id, basename, RoisN, path); 
print("Saving to",path);
showMessage("Finished");
setBatchMode(false);

// ---- Functions ----

// function to help calculate how many tiles to make in a row or column
function ceiling(value, tolerance) {
	// find the ceiling (smallest integer larger than the value), 
	// EXCEPT if this would result in a tile smaller than the minimum size set by the user
	if (value - round(value) > tolerance) {
		return round(value)+1;
	} else {
		return round(value);
	}
}

// function to add ROIs to the ROI manager, with the correct name
function addRoi(name) {
	image = getTitle();
	roinum = roiManager("Count");
	// name ROIs either anonymously or with the original image name
	if (name == "ROI number only") {
		Roi.setName("ROI #"+(roinum+1));
		}
	else if (outputName == "Original name") {
		Roi.setName(image+" ROI #"+(roinum+1));
		}
	roiManager("Add");
}

// function to create and save a regular non-overlapping grid of ROIs of the selected size
// covering the bounding box of the user's selection
function makeGrid(selectedWidth, selectedHeight, minimumSize, imageName, saveName, savePath) {
	run("Select None");
	setTool("polygon");
	waitForUser("Outline the section and click OK");
	// if there is no selection, use the whole image
	type = selectionType();
   	if (type==-1) {
		run("Select All");
   	}
	
	// add the tissue selection and get the bounding box
	Roi.setName("Selected Area");
	roiManager("Add"); // this is ROI index 0
	getSelectionBounds(x, y, width, height);

	// calculate how many boxes we will need based on the user-selected size 
	// regions at right and bottom edges may not not be included, based on minimum tile size set by user
	nBoxesX = ceiling(width/selectedWidth, minimumSize);
	nBoxesY = ceiling(height/selectedHeight, minimumSize);
	
	// remove any old overlays
	run("Remove Overlay");

	// create the grid of ROIs
	for(j=0; j< nBoxesY; j++) {
		for(i=0; i< nBoxesX; i++) {
			makeRectangle(x+i*selectedWidth, y+j*selectedHeight, selectedWidth,selectedHeight);
			addRoi(saveName);
		}
	}
	// save the full grid of ROIs
	run("Select None");
	roiManager("Deselect");
	roiManager("save", savePath+File.separator+imageName+"_AllROIs.zip");
}


// function to select random ROIs, create corresponding cropped images, and save
function selectAndSave(id, basename, ROIsWanted, savePath) {
	// make sure nothing is selected to begin with
	roiManager("Deselect");
	run("Select None");
	
	numTiles = roiManager("Count")-1; // one of the ROIs is the tissue area
	if (ROIsWanted >= numTiles) {
		showMessage("Not enough ROIs to select randomly. Saving all");
		ROIsWanted = numTiles;
		indices = Array.getSequence(numTiles);
	}
	else {
		indices = newArray(ROIsWanted);
	}
	
	// calculate how much to pad the ROI numbers
	digits = 1 + Math.ceil((log(ROIsWanted)/log(10)));
	count = 0;
	
	// select random tiles
	while(count < ROIsWanted) // loop until desired # ROIs is generated
		{ 
		index = floor(random * numTiles) + 1; // select from ROIs # 1 and up (ROI #0 is the tissue selection)
		
		// find the center of the initially selected roi
		roiManager("Select", index);
		Roi.getBounds(x, y, width, height);
		centerX = x + (width/2);
		centerY = y + (height/2);
		
		// check if the center of this roi is within the tissue selection
		roiManager("Select", 0); 
		if (selectionContains(centerX, centerY) == true) {
			indices[count] = index;
			roiNumPad = IJ.pad(count, digits);
			// set output image name
			if (outputName == "ROI number only") {
				cropName = "tile_"+roiNumPad;
			}
			else if (outputName == "Original name") {
				cropName = basename+"_tile_"+roiNumPad;
			}
			
			// create the image tile
			selectImage(id);
			roiManager("Select", indices[count]);
			run("Duplicate...", "title=&cropName duplicate");
			
			// add a 10 µm scale bar and save
			selectWindow(cropName);
			run("Scale Bar...", "width=10 height=1 thickness=5 font=14 color=Black background=None location=[Lower Right] horizontal hide");
			saveAs("tiff", savePath+File.separator+getTitle);
			close();
			
			count++;
		}
	}
	// save the randomly selected ROIs
	run("Select None");
	roiManager("Deselect");
	roiManager("select", indices);
	roiManager("save selected", savePath+File.separator+basename+"_SelectedROIs.zip");

}
