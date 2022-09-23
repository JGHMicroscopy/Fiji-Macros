// Proliferation Marker Expression- FIJI macro
// This macro was compiled for 4 cahnnel confocal z-stacks but will also accept 2D images.
// It aims to identify nuclei belonging to the ACTA2 region of the vessel wall and determine
// target fluorescence expression of PCNA or MKI67 colocalizing with the nuclear marker. 
// The information of the VWF channel is used to identify and exclude nuclei belonging to 
// the endothelium.

// Default saving location of the graphical output is "C:/Results", if this folder
// does not exist yet please create it. 

// Results are found in the Log window and are tab-separated.

// Requires FIJI with ImageJ vers. 1.53q

// Channel order:
// Ch1= DAPI/ nuclear marker
// Ch2= ACTA2/ marker for the cell population of interest
// Ch3= PCNA/MKI67 target for nuclear expression
// Ch4= VWF/ exclusion marker

// Settings below are also found in the GUI
// Default channel order can be changed here
CO=1234;
//Default nucleus thresholding algorithm can be adapted here
DAPITHA="MaxEntropy";
//Counting threshold = cells are counted as positive when target signal surpasses percentage 
CTH=10.0;
//Exclusion threshold = allowed overlap with exclusion channel
ETH=1;

CBT=0
DAPI= false
VWF= false
NW=0
NH=0
getDimensions(width, height, channels, slices, frames);
title=getTitle;
setForegroundColor(255, 255, 255);
setBackgroundColor(0, 0, 0);

Dialog.create("Welcome");
	Dialog.addMessage("Do you expect problems with the nuclear stain");
	Dialog.addCheckbox("YES",false);
	Dialog.addMessage("Do you expect problems with the endothelial marker");
	Dialog.addCheckbox("Yes",false);
	Dialog.addMessage("Select your nuclear marker threshold in %");
	Dialog.addNumber("       Threshold",CTH);
	Dialog.addMessage("Correct channel order");
	Dialog.addNumber("                ",CO);
	Dialog.show();
DAPI = Dialog.getCheckbox();
VWF = Dialog.getCheckbox();
CTH = Dialog.getNumber;
CO = Dialog.getNumber;

run("Clear Results");
roiManager("reset");
run("8-bit");
run("Arrange Channels...", "new="+CO);
if (slices>=2){
run("Z Project...", "projection=[Max Intensity]");
selectWindow(title); 
close();
selectWindow("MAX_"+title);
rename(title);
}
selectWindow(title);
run("Duplicate...", "title=A duplicate");
selectWindow(title); 
run("Split Channels");
selectWindow("C3-"+title);
run("Auto Threshold", "method=Yen white");
run("Merge Channels...", "c1=[C1-"+title+"] c2=[C2-"+title+"] c3=[C3-"+title+"] c4=[C4-"+title+"] create");
setTool("rectangle");
Stack.setDisplayMode("composite");

waitForUser("Please select the Vessel");
if (Roi.size>0){
	roiManager("Add");
	run("Crop");
	selectWindow("A"); 
	roiManager("Select", 0);
	run("Crop");
	roiManager("Delete");
	}
selectWindow(title);
NW = getWidth();
NH = getHeight();
run("Split Channels");
selectWindow("C1-"+title); 
	run("Enhance Contrast", "saturated=0.1");
	getMinAndMax(min,max);
	min=max/10;
	mi = round(min);
	setMinAndMax(mi,max);
	run("Gaussian Blur...", "sigma=2");
	if (DAPI==true) {
		run("Auto Threshold", "method=[Try all] white");
		selectWindow("Montage");
		FS= NH/10;
		setFont("SansSerif",FS,"Bold");
		setColor(200, 200, 200);
		drawString("Default",0,FS);
		drawString("Huang",NW,FS);
		drawString("Huang2",NW*2,FS);
		drawString("Internodes",NW*3,FS);
		drawString("IsoData",NW*4,FS);
		drawString("Li",0,FS+NH+15);
		drawString("MaxEntropy",NW,FS+NH+15);
		drawString("Mean",NW*2,FS+NH+15);
		drawString("MinError(I)",NW*3,FS+NH+15);
		drawString("Minimum",NW*4,FS+NH+15);
		drawString("Moments",0,FS+NH*2+40);
		drawString("Otsu",NW,FS+NH*2+40);
		drawString("Percentile",NW*2,FS+NH*2+40);
		drawString("Renyientropy",NW*3,FS+NH*2+40);
		drawString("Shanbhag",NW*4,FS+NH*2+40);
		drawString("Triangle",0,FS+NH*3+65);
		drawString("Yen",NW,FS+NH*3+65);
		selectWindow("Montage");
		NW2 = getWidth();
		NH2 = getHeight();
		run("Copy");
		newImage("Thresholding","8-bit",NW2*2,NH2,0);
		selectWindow("Thresholding");
		Image.paste(0,0);
		selectWindow("C1-"+title);
		run("Duplicate...", "title=A1 duplicate");
		selectWindow("A1");
		run("Size...", "width="+NW2+" height="+NH2+" average interpolation=Bilinear");
		run("Copy");
		selectWindow("Thresholding");
		Image.paste(NW2,0);
		selectWindow("A1");
		close();
		selectWindow("Montage");
		close();
		ar = newArray("Default", "Huang", "Huang2", "Internodes", "IsoData", "Li", "MaxEntropy", "Mean", "MinError(I)", "Minimum", "Moments", "Otsu", "Percentile", "RenyiEntropy", "Shanbhag", "Triangle", "Yen");
		Dialog.create("Nuclear thresholding");
		Dialog.addMessage("Please select the best thresholding algorythm")
	 	Dialog.addChoice("Type:", ar);
	 	Dialog.show();
	 	DAPITHA= Dialog.getChoice();
		selectWindow("Thresholding");
		close();
		selectWindow("C1-"+title);
		run("Auto Threshold", "method=["+DAPITHA+"] white"); 
		run("Make Binary");
		run("Watershed");
	}
	else if (DAPI==false) {
		selectWindow("C1-"+title);
		run("Auto Threshold", "method=[MaxEntropy] white"); 
		run("Make Binary");
		run("Watershed");
	}
if (VWF== false){
		selectWindow("C4-"+title); 
			run("Convolve...", "text1=[-1 -1 -1 -1 -1\n-1 -12 -6 -12 -1\n-1 -6 60 -6 -1\n-1 -12 -6 -12 -1\n-1 -1 -1 -1 -1\n] normalize");
			run("Auto Threshold", "method=MaxEntropy white");
			run("Make Binary");
		selectWindow("C1-"+title);
			run("Make Binary");
			run("Set Measurements...", "area mean standard area_fraction redirect=[C4-"+title+"] decimal=3");
			run("Analyze Particles...", "display add");
				for (i=0; i<roiManager("count"); i++) {
						if (getResult("%Area",i)>=ETH) { 
							roiManager("Select", i);
							run("Cut");
							}
				}
			if(roiManager("count")>0){
				roiManager("Deselect");
				roiManager("Delete");
			}	
			run("Clear Results");
		}	
selectWindow("C2-"+title); 
	run("Enhance Contrast", "saturated=0.1");
	getMinAndMax(min,max);
	min=max/10;
	mi = round(min);
	setMinAndMax(mi,max);
	run("Gaussian Blur...", "sigma=2");
	run("Auto Threshold", "method=[Try all] white");
selectWindow("Montage");
	FS= NH/10;
		setFont("SansSerif",FS,"Bold");
		setColor(200, 200, 200 );
		drawString("Default",0,FS);
		drawString("Huang",NW,FS);
		drawString("Huang2",NW*2,FS);
		drawString("Internodes",NW*3,FS);
		drawString("IsoData",NW*4,FS);
		drawString("Li",0,FS+NH+15);
		drawString("MaxEntropy",NW,FS+NH+15);
		drawString("Mean",NW*2,FS+NH+15);
		drawString("MinError(I)",NW*3,FS+NH+15);
		drawString("Minimum",NW*4,FS+NH+15);
		drawString("Moments",0,FS+NH*2+40);
		drawString("Otsu",NW,FS+NH*2+40);
		drawString("Percentile",NW*2,FS+NH*2+40);
		drawString("Renyientropy",NW*3,FS+NH*2+40);
		drawString("Shanbhag",NW*4,FS+NH*2+40);
		drawString("Triangle",0,FS+NH*3+65);
		drawString("Yen",NW,FS+NH*3+65);
		selectWindow("Montage");
		NW2 = getWidth();
		NH2 = getHeight();
		run("Copy");
		newImage("Thresholding","8-bit",NW2*2,NH2,0);
		selectWindow("Thresholding");
		Image.paste(0,0);
		selectWindow("C2-"+title);
		run("Duplicate...", "title=A2 duplicate");
		selectWindow("A2");
		run("Size...", "width="+NW2+" height="+NH2+" average interpolation=Bilinear");
		run("Copy");
		selectWindow("Thresholding");
		Image.paste(NW2,0);
		selectWindow("A2");
		close();
		selectWindow("Montage");
		close();
		ar = newArray("Default", "Huang", "Huang2", "Internodes", "IsoData", "Li", "MaxEntropy", "Mean", "MinError(I)", "Minimum", "Moments", "Otsu", "Percentile", "RenyiEntropy", "Shanbhag", "Triangle", "Yen");
		Dialog.create("ACTA2 thresholding");
		Dialog.addMessage("Please select the best thresholding algorythm")
	 	Dialog.addChoice("Type:", ar);
	 	Dialog.show();
		selectWindow("Thresholding");
		close();
		selectWindow("C2-"+title);
		ITH= Dialog.getChoice();
		run("Auto Threshold", "method=["+ITH+"] white"); 
		run("Make Binary");
	selectWindow("C2-"+title);
	run("Dilate");
	run("Dilate");
selectWindow("C1-"+title);
	run("Make Binary");
	run("Clear Results");
	run("Set Measurements...", "area mean standard redirect=[C2-"+title+"] decimal=3");
	run("Analyze Particles...", "size=0-Infinity display add");
	for (i=0; i<roiManager("count"); i++) {
			if (getResult("Mean",i)==0) { 
				roiManager("Select", i);
				run("Cut");
				}
	}
	if(roiManager("count")>0){
		roiManager("Deselect");
		roiManager("Delete");
	}
run("Clear Results");
	imageCalculator("OR create 32-bit", "C2-"+title,"C1-"+title);
selectWindow("Result of C2-"+title); 
	setMinAndMax(0, 255);
	run("8-bit");
	run("Make Binary");
selectWindow("C1-"+title);
	run("Make Binary");
	run("Set Measurements...", "area mean standard redirect=None decimal=3");
	run("Analyze Particles...", "size=10-Infinity display exclude summarize add");
selectWindow("C1-"+title);
		if(roiManager("count")>0){
			roiManager("Deselect");
			roiManager("Delete");
		}
	run("Analyze Particles...", "size=5-Infinity display exclude summarize add");
selectWindow("C3-"+title);
	roiManager("Show None");
	roiManager("Show All with labels");
	run("Clear Results");
	run("Set Measurements...", "area mean standard area_fraction redirect=None decimal=3");
	roiManager("Measure");
	selectWindow("Results"); 
		for (i=0; i<roiManager("count"); i++) {
				if (getResult("%Area",i)>= CTH){
				CBT++;			
				}
			}
		print(title,"	","Nuclei ("+DAPITHA+") in ACTA2 ("+ITH+")","	", roiManager("count"),"	","positive","	",CBT,"	","Yen");
selectWindow("A");
	run("Scale Bar...", "width=25 height=15 thickness=10 font=25 color=White background=None location=[Lower Right] horizontal bold overlay");
selectWindow("Result of C2-"+title);
	run("Dilate");
	run("Dilate");
	if(roiManager("count")>0){
			roiManager("Deselect");
			roiManager("Delete");
		}
	run("Analyze Particles...", "size=10-Infinity display summarize add");
	run("Invert");
	run("Analyze Particles...", "size=0-Infinity display exclude add");
selectWindow("A");
	Stack.setDisplayMode("composite");
	run("RGB Color");
	selectWindow("A (RGB)");
	roiManager("Set Color", "white");
	roiManager("Set Line Width", 4);
	roiManager("Show None");
	roiManager("Show All without labels");
	run("Flatten");
		if(roiManager("count")>0){
			roiManager("Deselect");
			roiManager("Delete");
		}
selectWindow("C1-"+title);
	run("Analyze Particles...", "size=5-Infinity display exclude summarize add");
	selectWindow("A (RGB)-1");
	roiManager("Show None");
	roiManager("Show All with labels");
	roiManager("Set Color", "yellow");
	roiManager("Set Line Width", 4);
	run("Flatten");
selectWindow("C3-"+title);
	run("Clear Results");
	run("Set Measurements...", "area mean standard area_fraction redirect=None decimal=3");
	roiManager("Measure");
	PC= newArray();
	for (i=0; i<roiManager("count"); i++) {
				if (getResult("%Area",i)<CTH){
				PC[i] = i;	
				print("Nucleus Nr.","	",i+1,"	","PCNA%","	",getResult("%Area",i));
				}
				else if (getResult("%Area",i)>=CTH){
				print("Nucleus Nr.","	",i+1,"	","PCNA%","	",getResult("%Area",i));	
				}
			}
	if(roiManager("count")>0){
	roiManager("select", PC);
	roiManager("Delete");
	}
	selectWindow("A (RGB)-2");
	roiManager("Show None");
	roiManager("Show All without labels");
	if(CTH>0){
	roiManager("Set Color", "red");
	}
	roiManager("Set Line Width", 4);
	run("Flatten");
	selectWindow("A (RGB)-3");
	saveAs("Jpeg", "C:/Results/"+title+"-ROI.jpg");
selectWindow("A (RGB)-1");
close();
selectWindow("Result of C2-"+title);
close();
selectWindow("A (RGB)");
close();
selectWindow("A (RGB)-2");
close();
selectWindow("A (RGB)-3");
close();
selectWindow("A");
close();
selectWindow("C4-"+title);
close();
selectWindow("C2-"+title);
close();
selectWindow("C1-"+title);
close();
selectWindow("C3-"+title);
close();
