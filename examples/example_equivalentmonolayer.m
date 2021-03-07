clear; close all;

addpath('/home/thomas/Documents/tinyfilters/research/wavepacket')

%% Create dielectric Fabry Perot filter using two materials

% Target central wavelength
targetcwl = 0.800; %micron


nair=1;
nsub=3.56; %silicon substarte

nl = 1.4; % low refractive index
nh = 2.4 % high refractive index

dh = targetcwl/(4*nh);%quarterwave 
dl = targetcwl/(4*nl);%quarterwave 

n = [nh nl nh nl nh nl nh [nl nl] nh nl nh nl nh nl nh];
thickness = [dh dl dh dl dh dl dh [dl dl] dh dl dh dl dh dl dh];

width=5.5; %micron


filter=tinyfilter(nair,n,nsub,thickness,width);


neff=nl*sqrt(1/(1-nl/nh+nl^2/nh^2));
    
%% Choose simulation options

polarisation = 's';

accuracy = 7;
wavelengths=linspace(0.73,0.85,300); % µm
angles = [0 5 10 15 20 ]; 

%% Run simulation for each angle
for a=1:numel(angles)
    

    %% Simulate
    disp(['Simulate tiny filter: ' num2str(angles(a)) ' deg']);
    
    Tclassic(:,a)=classictransmittance(filter,angles(a),wavelengths,polarisation);
    L=fwhm(wavelengths,Tclassic(:,1))/targetcwl;
    
    % Isimplicitly also unpolarized
    [Tmono]=tinytransmittance_mono(targetcwl,L,neff,width,nsub,angles(a),wavelengths,polarisation,accuracy);
    Tm(:,a)=Tmono;
    
    
    % Unpolarized 
    [Ttiny_s]=tinytransmittance(filter,angles(a),wavelengths,polarisation,accuracy);
    [Ttiny_p]=tinytransmittance(filter,angles(a),wavelengths,'p',accuracy);
    T(:,a)=0.5*(Ttiny_s+Ttiny_p);
    %    T(:,a)=Ttiny_s;
    
end


%% Plot transmittance
% There there is a drop in transmittance and an increase in FWHM
% 

cmap = hot;
s=size(cmap,1);
color{1}=cmap(1,:);
color{2}=cmap(round(0.45*s),:);
color{3}=cmap(round(0.5*s),:);
color{4}=cmap(round(0.6*s),:);
color{5}=cmap(round(0.66*s),:)


figure(1);clf;  hold on;
for a=1:numel(angles)
    htiny(a)=plot(wavelengths,T(:,a),'color',color{a},'linewidth',2)
    hmono(a)=plot(wavelengths,Tm(:,a)/max(Tm(:,1))*max(T(:,1)),'color','m','linewidth',2)
    hclassic=plot(wavelengths,Tclassic(:,a),':','color',color{a},'linewidth',1.5)
end




%% Labeling

text(0.73,0.6092,sprintf('Transmittance for\ninfinitely wide filter'))
line( [0.7617   0.7790],[ 0.5684    0.4888],'color','k')

text(0.73,0.2092,sprintf('Transmittance for\ntiny filter'))
line( [ 0.7608    0.7729],[  0.1969    0.1255],'color','k')

legend([htiny],'0^\circ','5^\circ','10^\circ','15^\circ','20^\circ')



ylabel('Transmittance')
xlabel('Wavelength (µm)')
title('Tiny vs. infinite transmittance')
box on
























