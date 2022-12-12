#@ File(label="Choose a directory containing 1000µmx1000µm images", style="directory") dir


//Require to concat array (see Array.concat)
setOption("ExpandableArrays", true);

list = getFilesList(dir,"jpg");

//Reset some parameters.
//Could be usefull to uncomment this part in case some default setting are not set
//setOption("Use inverting lookup table", false);
//setOption("DebugMode", false);
//setOption("Bicubic", true);
//setOption("Display Label", true);
//setOption("Limit to Threshold", false);
//setOption("BlackBackground", true);
//setBackgroundColor(0,0,0);
//setForegroundColor(255,255,255);

//run("Colors...", "foreground=white background=black selection=yellow");
//run("Options...", "iterations=1 count=1");
//run("Appearance...", "  menu=15 gui=1 16-bit=Automatic");



//Get threshold based on user input from the first image of the png image list
path = dir+File.separator+list[0];
//Get threshold on 1 image
open(path);
testImage=getTitle(); 
run("8-bit");
run("Threshold...");
waitForUser("Please adapt the upper threshold until the red selection completely covers the septal tissue.\n  (Do not click 'Apply').\n \nClick 'OK' when finished.");
getThreshold(lower, threshold);
run("Close");
close(testImage);
print("Threshold:"+threshold);
//}

//Set measurement settings and clear Results and ROI manager
run("Set Measurements...", "area mean min area_fraction redirect=None decimal=3");
run("Clear Results");
roiManager("reset");

//Open custom result table
title1 = "Morphometry"; 
title2 = "["+title1+"]"; 
f=title2; 
run("New... ", "name="+title2+" type=Table"); 
print(f,"\\Headings:slide\tPref\tPsep\tIntercepts"); 

//Open test systems
newImage("frame680", "8-bit black", 680, 680, 1);
setForegroundColor(255, 255, 255);
drawRect(0,0,680,1);
drawRect(0,0,1,680);
drawRect(0,679,680,1);
drawRect(679,0,1,680);
run("Invert LUT");

newImage("stepanizergrid680hor", "8-bit black", 680, 680, 1);
//setForegroundColor(255, 255, 255);
drawRect(57,92,567,1);
drawRect(57,163,567,1);
drawRect(57,233,567,1);
drawRect(57,304,567,1);
drawRect(57,375,567,1);
drawRect(57,446,567,1);
drawRect(57,516,567,1);
drawRect(57,587,567,1);
run("Invert LUT");
//run("Make Binary");

newImage("stepanizergrid680ver", "8-bit black", 680, 680, 1);
//setForegroundColor(0, 0, 0);
drawRect(92,57,1,567);
drawRect(163,57,1,567);
drawRect(233,57,1,567);
drawRect(304,57,1,567);
drawRect(375,57,1,567);
drawRect(446,57,1,567);
drawRect(516,57,1,567);
drawRect(587,57,1,567);
run("Invert LUT");
//run("Make Binary");

imageCalculator("AND create", "stepanizergrid680hor","stepanizergrid680ver");
//Invert the LUT so 0 is white and 255 is black
//run("Invert LUT");
run("Duplicate...", "title=stepanizerpoints680");
//rename("stepanizerpoints680")
selectWindow("Result of stepanizergrid680hor");
close();
//lll
//setForegroundColor(255, 255, 255);
for (i=0; i<list.length; i++) {
  showProgress(i, list.length);
  path = dir+File.separator+list[i];
  process(path,list[i],dir);
}

//Close all remaining screens except morphometry table
close("frame680");
close("stepanizergrid680hor");
close("stepanizergrid680ver");
close("stepanizerpoints680");
selectWindow("ROI Manager");
run("Close");
selectWindow("Results");
run("Close");

//Save morphometry table
selectWindow("Morphometry");
saveAs("Text", dir+File.separator+"Morphometry.csv");

function process(path,filename,dir)
{
//Open image and get names
  open(path);
  basename=getBaseName(filename);
  imageTitle=getTitle();

//Resize to fit frame680, grid680 and points680 (680pxx680px) => should not depend on size of image => adapt lines to image and ask for parameters (ask for parameters by user with function)
  run("Size...", "width=680 height=680 constrain interpolation=None");
  //save rescaled image
  run("Duplicate...", "title=rescaled");
  selectImage("rescaled");
  saveAs("BMP", dir+File.separator+basename+"_rescaled.bmp");
  close(basename+"_rescaled.bmp");

  //Select non-parenchymatous zones: already there
  selectImage(imageTitle);
  //clear ROI manager
  roiManager("reset");   
  //freehand selection tool
  setTool("polygon");
  //manual ROI selection
  waitForUser("ROI selection", "-Select all single non-parenchymal zones (arteries, veins, big airways, ...)\n  and add(t) one by one to the ROI manager.\n-Do not select anything if no non-parenchyma is present.\n \nClick 'OK' when finished");
  roiManager("Deselect");
  //save if any ROI selected
  if (roiManager("count")>0)
  {
    roiManager("save", dir+File.separator+basename+".zip");
  }

//Count amount of parenchymatous tissue: Pref
  selectImage("stepanizerpoints680");
  run("Duplicate...", "title=stepanizerpoints680@work");
  selectImage("stepanizerpoints680@work");
  //Remove the non-parenchymatous points
  //Select non-parenchymatous zones
  roiManager("Deselect");
  roiManager("Fill");
  //Clear ROI selection
  run("Select None");
  //Measure reference points
  run("Analyze Particles...", "display");
  selectWindow("Results");
  //Get value
  Pref=(nResults);
  run("Clear Results");
  roiManager("reset");

//Exsudate exclusion: step 1 AUTOMATIC
  //Get exudates from duplicate slide
  selectImage(imageTitle);
  //lll
  run("Select None");
  run("Duplicate...", "title=duplicate1");
  selectImage("duplicate1");
  run("8-bit");
  setThreshold(0, threshold);
  setOption("BlackBackground", false);
  run("Make Binary");
  imageCalculator("OR", "duplicate1","frame680");
  run("Analyze Particles...", "size=0-1000 add");
  //lll
  //save if any ROI selected and don't delete ROI's
  if (roiManager("count")>0)
  {
    roiManager("save", dir+File.separator+basename+"autoexudates.zip");
  }
  close("duplicate1");
  //Delete exudates on original image
  run("Clear Results");
  //lll
//Exsudate exclusion: step 2 MANUAL   
  //Make image without nonpar and automatic exsudate exclusions
  selectImage(imageTitle);
  run("Select None");
  run("Duplicate...", "title=select_exudates_here");
  selectImage("select_exudates_here");
  //Open nonpar ROI, next to automatic exudates (still in ROImanager) and remove from image
  if (File.exists(dir+File.separator+basename+".zip"))
  {
    roiManager("Open", dir+File.separator+basename+".zip");
  }
  roiManager("Deselect");
  roiManager("Fill");
  roiManager("reset");
  //Manually select remaining exudates
  setTool("polygon"); 
  waitForUser("Exsudate selection","-Select all remaining exudates (neutrophils, debris, ...)\n  and add(t) to the ROI Manager.\n-Hold 'Shift' to select multiple areas.\n \nClick 'OK' when finished.");
  roiManager("Deselect");
  //Save if any exudates are selected
  if (roiManager("count")>0)
  {
    roiManager("save", dir+File.separator+basename+"manualexudates.zip");
  }
  close("select_exudates_here");
  if (File.exists(dir+File.separator+basename+"exudates.zip"))
  {
    roiManager("Open", dir+File.separator+basename+"exudates.zip");
  }

//Process image to mask
  selectImage(imageTitle);
  run("8-bit");
  setThreshold(0, threshold);
  setOption("BlackBackground", false);
  run("Convert to Mask");
  //Open automatic exsudate ROI (next to manual exudates which are still open) + remove pixels
  if (File.exists(dir+File.separator+basename+"autoexudates.zip"))
  {
    roiManager("Open", dir+File.separator+basename+"autoexudates.zip");
  }
  roiManager("Deselect");
  roiManager("Fill");
  roiManager("reset");  
  //Clean and smoothen mask
  run("Invert");  
  run("Analyze Particles...", "size=0-200 add");
  roiManager("Fill");
  roiManager("reset");
  run("Clear Results");
  run("Invert");  
  run("Remove Outliers...", "radius=2 threshold=50 which=Dark");
  run("Remove Outliers...", "radius=2 threshold=50 which=Bright");
  run("Dilate");
  run("Erode");

//Count septal points: Psep
  //lll
  imageCalculator("AND create", imageTitle,"stepanizerpoints680@work");
  //lll 
  //Count number of septal points (non parenchymal points were already removed above)
  selectImage("Result of "+imageTitle);
  run("Analyze Particles...", "display");
  //Save result summary
  selectWindow("Results");
  //Get values
  Psep=(nResults);
  run("Clear Results");
  close("Result of "+imageTitle);
  close("stepanizerpoints680@work");

//Count intercepts (crossings of tissue with random lines)
  selectImage(imageTitle);
  run("Find Edges");
  //Remove non-parenchyma lining 
  if (File.exists(dir+File.separator+basename+".zip"))
  {
    roiManager("Open", dir+File.separator+basename+".zip");
    roiManager("Deselect");
    roiManager("Fill");
    roiManager("reset");
  }
  //Save edge image
  run("Duplicate...", "title=edges");
    selectImage("edges");
  saveAs("Tiff", dir+File.separator+basename+"_edges.tif");
  close(basename+"_edges.tif");
  //vertical intercepts
    //Calculate vertical intercept image
    imageCalculator("AND create", imageTitle,"stepanizergrid680ver");
    selectImage("Result of "+imageTitle);
    //Count number of intercepts
    run("Analyze Particles...", "display");
    //Save result summary
    selectWindow("Results");
    //Get values
    Iver=(nResults);
    //Close image vertical intercepts
    selectImage("Result of "+imageTitle);
    close();
    run("Clear Results");
  //horizontal intercepts
    //Calculate horizontal intercept image
    imageCalculator("AND create", imageTitle,"stepanizergrid680hor");
    //lll
    selectImage("Result of "+imageTitle);
    //Count number of intercepts
    run("Analyze Particles...", "display");
    //Save result summary
    selectWindow("Results");
    //Get values
    Ihor=(nResults);
    //Close image vertical intercepts
    selectImage("Result of "+imageTitle);
    close();
    run("Clear Results");
  //Sum
  Intercepts=Iver+Ihor;
  //Close images
  selectImage(imageTitle);
  close() ;
  
//Print values in morphometry table
  print(f, basename+"\t"+Pref+"\t"+Psep+"\t"+Intercepts); 
}

//Return the base name of a file, e.g. "test.png" return "test", "test.2.png" return "test.2"
function getBaseName(name)
{
  dotIndex = lastIndexOf(name, ".");
  //Get the basename
  name = substring(name, 0, dotIndex);
  return name;
}


//Return a file list contain in the directory dir filtered by extension.
function getFilesList(dir, fileExtension) {  
  tmplist=getFileList(dir);
  list = newArray;
  imageNr=0;
  for (i=0; i<tmplist.length; i++)
  {
    if (endsWith(tmplist[i], fileExtension)==true)
    {
      list[imageNr]=tmplist[i];
      imageNr=imageNr+1;
      //print(tmplist[i]);
    }
  }
  Array.sort(list);
  return list;
}