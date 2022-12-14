//open file you want to analyzw;
setTool("polygon");
waitForUser("Select your polygon and click okay");
roiManager("Add");
Roi.getBounds(x, y, w, h);
saveSettings();
roiManager("Add");
i = 0; //Counter
RoisN =30; // number of ROIs, you can adjust this for the number of sections needed
trials = 100
original=getTitle();
setForegroundColor(255,0,0);

while(i < RoisN)
{
	roiManager("select", 0);
	x1 = random()*w + x; //takes random # between 0-1, multiplies times width
    y1 = random()*h + y; //same as above

    if (selectionContains(x1, y1) == true)
    {
    	makeRectangle(x1, y1, 500, 500); //this will make the dimesnions for the size of your regions, can change to fit needs)
    	roiManager("Add");
    	setResult("X", i, x1);
    	setResult("Y", i, y1);
    	v = getPixel(x1, y1);

    	if (bitDepth() == 24)
    	{
    		red = (v >> 16)&0xff;
    		green = (v >> 8)&0xff;
    		blue = v&0xff;
    		setResult("Red", i, red);
    		setResult("Green", i, green);
    		setResult("Blue", i, blue);
    	}

    	else 
    	{
    		setResult("Value", i, v);
    		updateResults;
    	}
    	i++;
    }
    
}

roiManager("show all with labels");
roiManager("select", 0);
roiManager("delete");
roiManager("select all");
