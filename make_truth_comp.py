import ROOT
from ROOT import gStyle, TGaxis, gROOT, TH1, TColor, TCanvas, TFile, TH1D, gPad, TLegend, kWhite, gDirectory

## No need to see the plots appear here
gROOT.SetBatch(1)
gStyle.SetLineWidth(3)
gStyle.SetOptStat(0)
gStyle.SetOptTitle(0)
gStyle.SetOptFit(0)
TGaxis.SetMaxDigits(4)

gStyle.SetTextSize(0.05)
gStyle.SetLabelSize(0.05,"xyzt")
gStyle.SetTitleSize(0.05,"xyzt")

gStyle.SetPadTickX(1)
gStyle.SetPadTickY(1)
gStyle.SetNdivisions(505, "XY")

gROOT .ForceStyle()

TH1.SetDefaultSumw2()
gStyle.SetLineWidth(3)

## Make some colorblind friendly objects
## From: https://personal.sron.nl/~pault/#sec:qualitative
kkBlue    = TColor(9000,   0/255., 119/255., 187/255.)
kkCyan    = TColor(9001,  51/255., 187/255., 238/255.)
kkTeal    = TColor(9002,   0/255., 153/255., 136/255.)
kkOrange  = TColor(9003, 238/255., 119/255.,  51/255.)
kkRed     = TColor(9004, 204/255.,  51/255.,  17/255.)
kkMagenta = TColor(9005, 238/255.,  51/255., 119/255.)
kkGray    = TColor(9006, 187/255., 187/255., 187/255.)

can = TCanvas("can", "can", 800, 800)
can .cd()

def make_generator_comp(outPlotName, inFileList, nameList, colzList, \
                        plotVar="q0", binning="100,0,5", \
                        labels="q_{0} (GeV); d#sigma/dq_{0} (#times 10^{-38} cm^{2}/nucleon)",
                        isLog=False):

    histList = []

    ## Loop over the input files and make the histograms
    for inFileName in inFileList:
        
        inFile = TFile(inFileName)
        inTree = inFile.Get("FlatTree_VARS")
        
        inTree.Draw(plotVar+">>this_hist("+binning+")", "(cc==1)*fScaleFactor")
        thisHist = gDirectory.Get("this_hist")
        thisHist .SetDirectory(0)
        thisHist .SetNameTitle("thisHist", "thisHist;"+labels)
        histList .append(thisHist)

    ## Get the maximum value
    maxVal   = 0
    for hist in histList:
        if hist.GetMaximum() > maxVal:
            maxVal = hist.GetMaximum()        

    ## Actually draw the histograms
    histList[0].Draw("HIST")
    histList[0].SetMaximum(maxVal*1.3)
    if not isLog: histList[0].SetMinimum(0)
    for x in reversed(range(len(histList))):
        histList[x].SetLineWidth(3)
        histList[x].SetLineColor(colzList[x])
        histList[x].Draw("HIST SAME")
    
    ## Now make a legend
    dim = [0.1, 0.85, 0.98, 1.0]
    leg = TLegend(dim[0], dim[1], dim[2], dim[3], "", "NDC")
    leg .SetShadowColor(0)
    leg .SetFillColor(0)
    leg .SetLineWidth(0)
    leg .SetTextSize(0.036)
    leg .SetNColumns(3)
    leg .SetLineColor(kWhite)
    for hist in range(len(histList)):
        leg .AddEntry(histList[hist], nameList[hist], "l")
    leg .Draw("SAME")

    gPad.SetLogy(0)
    if isLog: gPad.SetLogy(1)
    gPad.SetRightMargin(0.03)
    gPad.SetTopMargin(0.15)
    gPad.SetLeftMargin(0.2)
    gPad.SetBottomMargin(0.15)
    gPad.RedrawAxis()
    gPad.Update()
    can .SaveAs(outPlotName)

if __name__ == '__main__':


    ## These files can be found here (no login required): https://portal.nersc.gov/project/dune/data/2x2/simulation
    inFileList = ["flat_trees/NuMIME_FHC_numu_Ar40_GENIEv3_G18_10a_00_000_1M_0000_NUISFLAT.root",\
                  "flat_trees/NuMIME_FHC_numu_Ar40_GENIEv3_G18_10b_00_000_1M_0000_NUISFLAT.root",\
                  "flat_trees/NuMIME_FHC_numu_Ar40_GENIEv3_G18_10c_00_000_1M_0000_NUISFLAT.root",\
                  "flat_trees/NuMIME_FHC_numu_Ar40_GENIEv3_CRPA21_04a_00_000_1M_0000_NUISFLAT.root",\
                  "flat_trees/NuMIME_FHC_numu_Ar40_GENIEv3_G21_11a_00_000_1M_0000_NUISFLAT.root",\
                  "flat_trees/NuMIME_FHC_numu_Ar40_NEUT_1M_0000_NUISFLAT.root",\
                  "flat_trees/NuMIME_FHC_numu_Ar40_NUWRO_LFGRPA_1M_0000_NUISFLAT.root"\
                  ]
    nameList = ["GENIEv3 10a",\
                "GENIEv3 10b",\
                "GENIEv3 10c",\
                "CRPA",\
                "SuSAv2",\
                "NEUT",\
                "NuWro"\
                ]
    colzList = [9000, 9001, 9002, 9003, 9004, 9006, 9005]

    ## Make a comparison as a function of q0 for funsies
    make_generator_comp("generator_comp_q0.png", inFileList, nameList, colzList, "q0", "100,0,5", \
                        "q_{0} (GeV); d#sigma/dq_{0} (#times 10^{-38} cm^{2}/nucleon)")
    
    ## N tracks
    make_generator_comp("generator_comp_ntracks.png", inFileList, nameList, colzList, \
                        "Sum$(pdg==2212 || abs(pdg)==211 || abs(pdg)==13 || abs(pdg)==321)", "15,0,15", \
                        "N. tracks; d#sigma/d(N. tracks) (#times 10^{-38} cm^{2}/nucleon)")    

    ## N mips
    make_generator_comp("generator_comp_nmips.png", inFileList, nameList, colzList, \
                        "Sum$(abs(pdg)==211 || abs(pdg)==13)", "10,0,10", \
                        "N. MIPs; d#sigma/d(N. MIPs) (#times 10^{-38} cm^{2}/nucleon)")  

    ## N protons
    make_generator_comp("generator_comp_nprotons.png", inFileList, nameList, colzList, \
                        "Sum$(pdg==2212)", "10,0,10", \
                        "N. protons; d#sigma/d(N. protons) (#times 10^{-38} cm^{2}/nucleon)")
