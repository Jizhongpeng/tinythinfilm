
function [T,Phi_t,Phi_in] = tinytransmittance3d_mono(central_wavelength,normalized_fwhm,effective_index,width,nsub,angledeg,wavelengths,polarization,pixelkernel,accuracy);
%  TINYTRANSMITTANCE3D_MONO  Simulate tiny filter transmittance
%   [T] = TINYTRANSMITTANCE3D_MONO(filter,angledeg,wavelengths,polarization,accuracy);
%    
%   Inputs
%    - filter : Struct containing the tiny filter design (See also TINYFILTER)
%    - angledeg:  Incidence angle in degrees
%    - wavelengths (Wx1): Wavelengths (same units as filter.width of filter)
%    - polarization ('s' or 'p')    
%    - accuracy: 2^floor(accuracy) subdivision of the spatial frequency domain.
%   Outputs
%    - T (Wx1):  Transmittance of the filter
%    - Phi_T (Wx1):  Transmitted flux [W]
%    - Phi_T (Wx1):  Incident flux [W]
%    
%    
%  See also TINYFILTER    
%  Copyright Thomas Goossens  
%  http://github.com/tgoossens
    
    
wl=reshape(wavelengths,[1 1 numel(wavelengths)]);
anglerad=deg2rad(angledeg); 
neff=effective_index;
cwl=central_wavelength;

% Spatial frequency integration domain
nu_x = linspace(-1/wl(1), 1/wl(1),2^floor(accuracy))';
nu_y=nu_x';
nu = sqrt(nu_x.^2+nu_y.^2);
%nu = linspace(-10/wl(1), 10/wl(1),2^floor(accuracy))';



%% Definitions and helper ufcntions

% Wavenumber
k = @(n) 2*pi./(wl)*n; 

% Fourier transform of the pixel kernel (so we don't recompute it for each wavelength)
fftpix=fft(pixelkernel(nu));
conv_pix=@(f) conv2(conv2(f,pixelkernel(nu_x),'same'),pixelkernel(nu_y),'same');

%
% 
%% Definitions alpha and k
k = 2*pi./(wl)*neff;

alpha = @(v) sqrt(k.^2-(2*pi*v).^2);

% Half wave plate
h = cwl/(2*neff);


%%  Calculate admittances

% Complex surface admittance of filter stack
% We will only use the transmission coefficient here
% Admittances of each layer

eta = admittance(nsub,wl,nu,polarization);
eta_sub=eta(1);

eta = admittance(1,wl,nu,polarization);
eta_in=eta(1);


%% Conversion functions
d=@(alpha) 0.5*pi*alpha; %delta
fwhm2r=@(alpha)-sqrt(cos(2*d(alpha)).^2-4*cos(2*d(alpha))+3)-cos(2*d(alpha))+2    ;

R = fwhm2r(normalized_fwhm);

delta = alpha(nu).*h;


ts=2*eta_in./(eta_sub+eta_in); 

t = ts.*(1-R).*  1./(1-R*exp(1i*2*delta));



for j=1:numel(wl)
    %%%%%%%%%% WAVE AMPLITUDES %%%%%%%%%%%%
    % Incident wwave
    width_y=width;
    Ain(:,:,j) = width_y *width*sinca(pi*width*(nu_x-sin(anglerad)/wl(j))).*sinca(pi*width_y*(nu_y)/wl(j));

    % Useful integration domain;. This conditions corresponds to ignore incidence angles larger than 90 degres.
    domain = abs(nu).*wl(j) <=1;
    
    % Transmitted wave
    At(:,:,j)=domain.*t(:,:,j).*Ain(:,:,j);
    
    %%%%%%%%%% FLUXES  %%%%%%%%%%%%
    %Incident flux (explicit result)
    nu_angle=sin(anglerad)/wl(j);
    eta_in = admittance(1,wl(j),nu_angle,polarization);
    Phi_in(j)=real(eta_in(1))/2 * width*width_y;
    
    
    % Transmitted flux
    temp=  0.5*real(eta_sub(:,:,j).*At(:,:,j).*conv_pix(conj(At(:,:,j))));
    temp= temp*abs(nu_x(2)-nu_y(1))*abs(nu_y(2)-nu_y(1)); % discretization convolution integral
    Phi_t(j)=trapz(nu_y,trapz(nu_x,temp,1),2); 
    
end


% Transmittance
T=Phi_t./Phi_in;





function f = sinca(x)
% Modified sinc function because matlab sinc function already includes the factor pi.
% This makes notation consistent with definitions in the publications.    
    f=sinc(x/pi); 
end
end