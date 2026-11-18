Series=nImages;
for (MK = 0; MK < Series; MK++) {
//Setup
tit= getTitle();
titend= tit.length;
FS=indexOf(tit, "-");
name1=substring(tit, 0, FS);
name2=substring(tit, FS+1, titend);
saving=name1+"_"+name2;
rename("Image");
name= "Image";
//set channels here if not all are desired in the analysis 
//First channel needs to be the nuclear information 
//Channel 3 is optionl
run("Arrange Channels...", "new=412");
getDimensions(W, H, channels, slices, frames);
getPixelSize(unit, pixelWidth, pixelHeight);
setForegroundColor(255, 255, 255);
setBackgroundColor(0, 0, 0);
if (channels==1) {
	close(tit);
	continue;
}
run("Set Measurements...", "area mean standard center shape redirect=None decimal=3");
run("Duplicate...", "duplicate");
roiManager("reset");
run("Clear Results");
run("8-bit");
//Analysis of the nucleus Channel
run("Split Channels");
selectWindow("C1-"+name+"-1");
run("Gaussian Blur...", "sigma=2");
run("Auto Threshold", "method=[Otsu] white");
run("Fill Holes");
run("Analyze Particles...", "size=35-Infinity exclude add");
total_nuclei=roiManager("count");
//Thresholding Cell
if (channels>2){
	selectWindow("C2-"+name+"-1");
	run("Duplicate...", " ");
	run("Gaussian Blur...", "sigma=2");
	selectWindow("C3-"+name+"-1");
	run("Duplicate...", " ");
	run("Gaussian Blur...", "sigma=2");
	imageCalculator("Add create", "C2-Image-1-1","C3-Image-1-1");
	selectWindow("C3-"+name+"-1-1");
	close;
	selectWindow("C2-"+name+"-1-1");
	close;
	selectImage("Result of C2-Image-1-1");
	run("Auto Threshold", "method=[Huang] white");
	run("Erode");
	run("Analyze Particles...", "size=1000-3000 display add");
}
if (channels==2) {
selectWindow("C2-"+name+"-1");
run("Duplicate...", " ");
run("Gaussian Blur...", "sigma=2");
run("Auto Threshold", "method=[Huang] white");
run("Erode");
run("Analyze Particles...", "size=1000-3000 display add");
}
if (roiManager("count")==total_nuclei) {
	setTool("wand");
	waitForUser("Select Cells");
	roiManager("add");
	roiManager("Measure");
}
total_cells=roiManager("count");
wait(10);
//Channel2 Outline
newImage("Cells", "8-bit black", W, H, 1);
wait(10);
roiManager("Show None");
for (i = total_nuclei; i < roiManager("count"); i++) {
	roiManager("select", i);
	run("Invert");
}
//Analysing Nucleus Information
newImage("Nuclei", "8-bit black", W, H, 1);
wait(10);
roiManager("Show None");
for (i = 0; i < total_nuclei; i++) {
	roiManager("select", i);
	run("Invert");
}
// calculate cell and nuecleus overlap
// step one only have cells with nuclei left
selectWindow("Nuclei");
for (i = total_nuclei; i < total_cells; i++) {
	roiManager("select", i);
	roiManager("measure");
	if (getResult("Mean", nResults-1)== 0 ) {
		selectWindow("Cells");
		roiManager("select", i);
		run("Invert");
		selectWindow("Nuclei");
	}
}
// step two only have cells with nuclei left
imageCalculator("AND", "Nuclei","Cells");
//cleanup
close("C1-Image-1");
if (channels==2) {
	close("C2-Image-1-1");
}
if (channels==3) {
	close("Result of C2-Image-1-1");
}
//sorting cells and nuclei 
roiManager("reset");
run("Clear Results");
selectImage("Cells");
roiManager("show all");
roiManager("Show None");
run("Analyze Particles...", "size=0-infinity add");
cells=roiManager("count");
if (cells==0) {	
	selectWindow("Image");
	saveAs("Tiff", "/home/juergen-gindlhuber/Desktop/REsults/Errors/"+saving+".tif");
	close("C2-Image-1");
	close("C1-Image-1");
	close("Nuclei");
	close(saving+".tif");
	close("Cells");
	if (channels>2) {
		close("C3-Image-1");
	}
	continue;
}
selectImage("Nuclei");
roiManager("show all");
roiManager("Show None");
run("Analyze Particles...", "size=0-infinity add");
ROI_memory= roiManager("count");
nuclei=ROI_memory-cells;
if (nuclei<=0) {	
	selectWindow("Image");
	saveAs("Tiff", "/home/juergen-gindlhuber/Desktop/REsults/Errors/"+saving+".tif");
	close("C2-Image-1");
	close("C1-Image-1");
	close(saving+".tif");
	close("Nuclei");
	close("Cells");
	if (channels>2) {
		close("C3-Image-1");
	}
	continue;
}
//start single cell analysis 
for (c = 0; c < cells; c++) {
	run("Clear Results");
	run("Set Measurements...", "area mean standard center shape redirect=None decimal=3");
	newImage("Single Cell", "8-bit black", W, H, 1);
	roiManager("select", c);
	run("Invert");
	roiManager("measure");
	Cell_Size=((pixelHeight*pixelWidth)*getResult("Area", 0));
	imageCalculator("AND create", "Nuclei","Single Cell");
	imageCalculator("XOR", "Single Cell","Result of Nuclei");
	run("Clear Results");
	selectWindow("Result of Nuclei"); 
	wait(10);
	run("Clear Results");
	run("Analyze Particles...", "size=0-infinity display");
	single_cell_nuclei=nResults;
	if (single_cell_nuclei>1) {
		run("Summarize");
		Nuc_Size=(pixelHeight*pixelWidth)*getResult("Area",single_cell_nuclei);
		Circ=getResult("Circ.", single_cell_nuclei);
		AR=getResult("AR", single_cell_nuclei);
		Round=getResult("Round", single_cell_nuclei);
		Solidity=getResult("Solidity", single_cell_nuclei);
		}
	else {
		Nuc_Size=(pixelHeight*pixelWidth)*getResult("Area", 0);
		Circ=getResult("Circ.", 0);
		AR=getResult("AR", 0);
		Round=getResult("Round", 0);
		Solidity=getResult("Solidity", 0);
	}
	XM= newArray();
	YM= newArray();
	for (i = 0; i < single_cell_nuclei; i++) {
		XM[i]=(getResult("XM", i));
		YM[i]=(getResult("YM", i));
	}
	Width_Nuclei=0; //Nucleus Total Width 
	Length_Nuclei=0; //Nucleus Total Lenght
	Wall_Distance=0;
		// Managing the nuclear envelope 
		EP=floor(0.6/pixelWidth);//Envelope pixels
		selectWindow("Result of Nuclei");
		roiManager("deselect");
		roiManager("Show None");
		run("Clear Results");
		run("Duplicate...", " ");
		for (i = 0; i < EP; i++) {
			run("Erode");
		}
		selectWindow("Result of Nuclei");
		for (i = 0; i < EP; i++) {
			run("Dilate");
		}
		run("Set Measurements...", "area mean standard center shape redirect=C2-Image-1 decimal=3");
		selectImage("Result of Nuclei-1");
		run("Analyze Particles...", "display exclude add");
		if (nResults>1) {
			run("Summarize");
			MFINC2=getResult("Mean", nResults-4);
		}
		else {
			MFINC2=getResult("Mean", 0);
		}
		run("Clear Results");
		selectImage("Result of Nuclei");
		for (i = ROI_memory; i < ROI_memory+single_cell_nuclei; i++) {
			roiManager("select", i);
			run("Invert");
		}
		roiManager("Show All");
		roiManager("Show None");
		run("Analyze Particles...", "display exclude add");
		if (nResults>1) {
			run("Summarize");
			MFINE2=getResult("Mean", nResults-4);
		}
		else {
			MFINE2=getResult("Mean", 0);
		}
		//print(MFINC2, MFINE2);
		//Channel 3 Nuclear measurement
		if (channels>2){
			run("Clear Results");
			run("Set Measurements...", "area mean standard center shape redirect=C3-Image-1 decimal=3");
			selectImage("Result of Nuclei-1");
			run("Analyze Particles...", "display exclude");
			if (nResults>1) {
				run("Summarize");
				MFINC3=getResult("Mean", nResults-4);
			}
			else {
				MFINC3=getResult("Mean", 0);
			}
			run("Clear Results");
			selectImage("Result of Nuclei");
			roiManager("Show All");
			roiManager("Show None");
			run("Analyze Particles...", "display exclude");
			if (nResults>1) {
				run("Summarize");
				MFINE3=getResult("Mean", nResults-4);
			}
			else {
				MFINE3=getResult("Mean", 0);
			}
		//print(MFINC3, MFINE3);
		}
		//get cytoplasmic MFI
		run("Clear Results");
		selectWindow("Single Cell");
		run("Fill Holes");
		roiManager("Show All");
		roiManager("Show None");
		for (i = ROI_memory+single_cell_nuclei; i<roiManager("count"); i++) {
			roiManager("select", i);
			run("Invert");
		}
		roiManager("Show All");
		roiManager("Show None");
		run("Set Measurements...", "mean standard redirect=C2-Image-1 decimal=3");
		run("Analyze Particles...", "size=200-Infinity display");
		MFI2= getResult("Mean", 0);
		if (channels>2) {
			run("Set Measurements...", "mean standard redirect=C3-Image-1 decimal=3");
			run("Analyze Particles...", "size=200-Infinity display");
			MFI3= getResult("Mean", 1);
		}
		//print(MFI2,MFI3,LI[0],WI[0]);
		
		if (channels>2) {
			print(saving+"_cell"+(c+1),",","Cell Size",",",Cell_Size,",","MFI Channel2",",",MFI2,",","Channel2 Nuclear core MFI",",",MFINC2,",","Channel2 Nuclear envelope MFI",",",MFINE2,",","MFI Channel3",",",MFI3,",","Channel3 Nuclear core MFI",",",MFINC3,",","Channel3 Nuclear envelope MFI",",",MFINE3,",","Nuclei in the cell",",",single_cell_nuclei,",","Min. distance to cell wall",",",Wall_Distance,",","Nucleus Area",",",Nuc_Size,",",",","Nucleus Length",",",Length_Nuclei,",","Nucleus Width",",", Width_Nuclei ,",","Circularity",",",Circ,",","Aspect ratio",",",AR,",","Roundnes",",",Round,",","Solidity",",",Solidity);
			if (RMC-Single_cell_ROIs>0) {
			}
			if (RMC-Single_cell_ROIs==0) {
				print("Nucleus is in the centroid");
			}
		}
		else {
			print(saving+"_cell"+(c+1),",","Cell Size",",",Cell_Size,",","MFI Channel2",",",MFI2,",","Nuclear core MFI",",",MFINC2,",","Nuclear envelope MFI",",",MFINE2,",","Nuclei in the cell",",",single_cell_nuclei,",","Min. distance to cell wall",",",Wall_Distance,",","Nucleus Area",",",Nuc_Size,",","Nucleus Length",",",Length_Nuclei,",","Nucleus Width",",", Width_Nuclei ,",","Circularity",",",Circ,",","Aspect ratio",",",AR,",","Roundnes",",",Round,",","Solidity",",",Solidity);
			if (RMC-Single_cell_ROIs>0) {
			}
			if (RMC-Single_cell_ROIs==0) {
				print("Nucleus is in the centroid");
			}
		}
		setTool("rectangle");
		if (RMC-Single_cell_ROIs>0) {
			selectImage("Kinase Distribution "+name);
			saveAs("Jpeg", "/home/juergen-gindlhuber/Desktop/REsults/Plots/Kinase Distribution "+saving+"_cell"+(c+1)+".jpg");
			close;
			close("Kinase Distribution "+name);
			analysis_ROIs=newArray(RMC-ROI_memory);
			analysis_ROIsi=0;
			selectWindow("Image");
			roiManager("show all");
			roiManager("show none");
			roiManager("deselect");
			run("Duplicate...", "duplicate");
			for (i = ROI_memory; i < RMC; i++) {
				roiManager("Select", i);
   				Overlay.addSelection;
				analysis_ROIs[analysis_ROIsi]=i;
				analysis_ROIsi++;
			}
			Property.set("CompositeProjection", "Sum");
			Stack.setDisplayMode("composite");
			Overlay.show;
			Overlay.flatten;
			selectImage("Image-1 (RGB)");
			saveAs("Jpeg", "/home/juergen-gindlhuber/Desktop/REsults/ROIs/"+saving+"_cell"+(c+1)+".jpg");
			close("Image-1 (RGB)");
			close("Single Cell");
			close("Result of Nuclei");
			close("Result of Nuclei-1");
			roiManager("select", analysis_ROIs);
			roiManager("delete");
			Overlay.clear;
		}
		else {
			close("Single Cell");
			close("Result of Nuclei");
			close("Result of Nuclei-1");
			for (i = ROI_memory; i < Single_cell_ROIs; i++) {
				roiManager("select", ROI_memory);
				roiManager("delete");
			}
		}
	}
close("C2-Image-1");
close("Image");
close("Nuclei");
close("Cells");
if (channels>2) {
	selectImage("C3-Image-1");
	close;
	run("Collect Garbage");
	run("Collect Garbage");
	}
}