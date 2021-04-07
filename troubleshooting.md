# Troubleshooting your gaussian calculations  
## Gaussian Troubleshooting Resources  

[Compute Canada](https://docs.computecanada.ca/wiki/Gaussian_error_messages): The compute canada website has a collection of error descriptions, explanations, and fixes.

## "CPHF failed to converge in LinEq2"  

**Error Explanation:** This error can occur when calculating frequencies on a large structure (ex. 100 atoms or more). When calculating DFT frequencies gaussian has two methods. The first stores calculation data in RAM. This makes the calculation much faster and reliable, however, if gaussian runs low on memory or if the system your are calculating frequencies on is large it defaults to a slower method. The slower method stores the calculation data on disk which greatly increases the calculation time (reading from and writing to  disk is significantly slower than the same processes when using RAM). This method is also much less reliable and regularly fails which prints the error above. This can be solved by forcing gaussian to run the calculation using the in-RAM algorithm.  

**Error Fix:** The in-RAM algorithm can essentially be forced by reducing the two-electron integral accuracy using the command  `Int=Acc2E=11` in the route section of your calculation. Alternatively, the size of the reduced space for in-RAM inversion can be increased by using `CPHF(MaxInv=10000)`.  `Int=Acc2E=11` decreases the accuracy of two-electron integrals from 10<sup>-12</sup> to 10<sup>-11</sup> and as a result Gaussian will more likely use the in-RAM method. From the [Gaussian website](https://gaussian.com/integral/):  

> **Int=Acc2E=N** 
>
> Set 2-electron integral accuracy to 10<sup>–N</sup>. The default is 10<sup>-12</sup>.  

`CPHF(MaxInv=10000)` again will make it more likely that gaussian uses the in-RAM method. If this does not work you can try increasing the value further, however, I do not know if there is an upper limit to what Gaussian will accept. Notably, this command does not effect the accuracy of the frequency calculation and for that reason I would advise using it over `Int=Acc2E=11`. From the [Gaussian website](https://gaussian.com/cphf/):  

> **MaxInv=N**
>
> Specifies the largest reduced space for in-core inversion during simultaneous solution (up to dimension N). Larger reduced problems are solved by a second level of DIIS. The default is 5000. 

**Example usage:** `# freq b3lyp/6-31g* empiricalDispersion=gd3bj Int=Acc2E=11` 
or `# freq b3lyp/6-31g* empiricalDispersion=gd3bj CPHF(MaxInv=10000)`  
**NOTE:** Make sure enough memory is requested for gaussian to actually run the calulation in RAM.  
**NOTE:** Since `Int=Acc2E=11` decreases the accuracy of two-electron integrals I would recommend only using this if your frequency calculations are still failing after trying `CPHF(MaxInv=10000)`.  

## "OrtVc1 failed #1"  

**Error Explanation:** This occurs during a frequency calculation when Raman intensities are predicted. I have found one good [resource](https://www.somewhereville.com/2015/01/01/ortvc1-failed-1-workaround-in-gaussian09-warning-about-pre-resonance-raman-spectra-in-gaussview-45/) with an explanation of the error but I will summarize their explanation. Raman intensity calculations use coupled perturbed Hartree-Fock ([CPHF](https://gaussian.com/cphf/)) which can give an error when running a calculation with both molecular symmetry and the fast multipole method ([FMM](https://gaussian.com/fmm/)) turned on. FMM is turned on or off depending on whether Gaussian predicts it will give a significant speed increase and not introduce and significant errors. Therefore, to remedy this problem A workaround can be used. 

**Error Fix:** <add in once known>  



