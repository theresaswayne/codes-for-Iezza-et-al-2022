#@ int(label="Width of tiles in pixels:") tileWidth
#@ int(label="Height of tiles in pixels:") tileHeight
#@ int(label="Number of ROIs to generate:") RoisN
#@ double (label="Minimum tile size (as a fraction of desired tile size:", style="slider", value = 0.2, min=0, max=1, stepSize=0.1) minSize
#@ File (label = "Output directory", style = "directory") path

// ImageJ macro
// How to use: 
//     Open an image and run the script.


// ---- Setup ----

roiManager("reset");

// get image info
id = getImageID();
title = getTitle();
dotIndex = indexOf(title, ".");
basename = substring(title, 0, dotIndex);


//setTool("polygon");
//waitForUser("Select your polygon and click okay");
//roiManager("Add");
//Roi.getBounds(x, y, w, h);
//saveSettings(); //???
//roiManager("Add");


// ---- Run the functions ----

setBatchMode(true); // greatly increases speed and prevents lost tiles
makeGrid(tileWidth, tileHeight, minSize, basename, path);
//selectROIs(RoisN);
selectAndSave(id, basename, RoisN, path); 
print("Saving to",path);
showMessage("Finished");
setBatchMode(false);

//
//i = 0; //Counter
//// RoisN =10; // number of ROIs, you can adjust this for the number of sections needed
//trials = 100
//original=getTitle();
//setForegroundColor(255,0,0);
//
//while(i < RoisN)
//{
//	roiManager("select", 0);
//	x1 = random()*w + x; //takes random # between 0-1, multiplies times width
//    y1 = random()*h + y; //same as above
//
//    if (selectionContains(x1, y1) == true)
//    {
//    	makeRectangle(x1, y1, tileWidth, tileHeight); //this will make the dimesnions for the size of your regions, can change to fit needs)
//    	roiManager("Add");
//    	setResult("X", i, x1);
//    	setResult("Y", i, y1);
//    	v = getPixel(x1, y1);
//
//		// record RGB pixel values
//    	if (bitDepth() == 24)
//    	{
//    		red = (v >> 16)&0xff;
//    		green = (v >> 8)&0xff;
//    		blue = v&0xff;
//    		setResult("Red", i, red);
//    		setResult("Green", i, green);
//    		setResult("Blue", i, blue);
//    	}
//
//    	else 
//    	{
//    		// record grayscale pixel value
//    		setResult("Value", i, v);
//    		updateResults;
//    	}
//    	i++;
//    }
//    
//}

//roiManager("show all with labels");
//roiManager("select", 0); // the original polygon
//roiManager("delete");
//roiManager("select all");



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
function makeGrid(selectedWidth, selectedHeight, minimumSize, imageName, savePath) {
	
	
	setTool("polygon");
	waitForUser("Select your polygon and click okay");
	
	//Make grid based on selection or whole image
	roiManager("Add");
	getSelectionBounds(x, y, width, height);
	
	// Set Color
	color = "red";

	// Calculate how many boxes we will need based on the user-selected size 
	// --  note that thin edges will not be converted, based on tolerance in ceiling function
	nBoxesX = ceiling(width/selectedWidth, minimumSize);
	nBoxesY = ceiling(height/selectedHeight, minimumSize);
	
	run("Remove Overlay");
	// roiManager("Reset");

	for(j=0; j< nBoxesY; j++) {
		for(i=0; i< nBoxesX; i++) {
			makeRectangle(x+i*selectedWidth, y+j*selectedHeight, selectedWidth,selectedHeight);
			addRoi();
		}
	}

	run("Select None");
	roiManager("save", savePath+File.separator+imageName+"_AllROIs.zip");
}




// function to select random ROIs, create corresponding cropped images, and save
function selectAndSave(id, basename, ROIsWanted, savePath) {

	// make sure nothing is selected to begin with
	roiManager("Deselect");
	run("Select None");
	
	indices = newArray(ROIsWanted);
	roinum = roiManager("Count");
	
	if (ROIsWanted >= roinum) {
		print("Not enough ROIs to select randomly. Saving all");
		indices = Array.getSequence(n);
	}

	
	//numROIs = roiManager("count");
	// calculate how much to pad the ROI numbers
	digits = 1 + Math.ceil((log(ROIsWanted)/log(10)));
	
	for(count=0; count <= ROIsWanted; count++) // loop through ROIs and save
		{ 
		index = floor(random * roinum) + 1; // ROIs 1 and up
		roiManager("Select", index);
		Roi.getBounds(x, y, width, height);
		centerX = x + (width/2);
		centerY = y + (height/2);
		// here, check if the center of the roi is in the selection
		roiManager("Select", 0); 
		if (selectionContains(centerX, centerY) == true) {
			indices[count] = index;
		
			roiNumPad = IJ.pad(count, digits);
			cropName = basename+"_tile_"+roiNumPad;
			selectImage(id);
			roiManager("Select", indices[count]);
			
			setResult("X", count, x);
			setResult("Y", count, y);
			v = getPixel(x, y);
			
			if (bitDepth() == 24) {
				// record RGB pixel values
	    		red = (v >> 16)&0xff;
	    		green = (v >> 8)&0xff;
	    		blue = v&0xff;
	    		setResult("Red", i, red);
	    		setResult("Green", i, green);
	    		setResult("Blue", i, blue);
		    	}
		    else {
	  			// record grayscale pixel value
		    	setResult("Value", i, v);
		    	}
	    	updateResults;
			run("Duplicate...", "title=&cropName duplicate"); // creates the cropped image
			selectWindow(cropName);
			saveAs("tiff", savePath+File.separator+getTitle);
			close();
		}
		}	
	run("Select None");
	
	
	roiManager("Deselect");
	roiManager("select", indices);
	roiManager("save selected", savePath+File.separator+basename+"_SelectedROIs.zip");

}

