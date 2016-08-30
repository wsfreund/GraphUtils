%function [regions,ax,lnkObj] = plotuncertain(axesH,t,y,...
%   stdev,color)
function [regions] = plotuncertain(axesH,t,y,stdev,color)
%
% TODO Help
%

% - Creation Date: Sat, 19 Oct 2013
% - Last Modified: Sun, 10 Aug 2014
% - Author(s): 
%   - W.S.Freund <wsfreund_at_gmail_dot_com> 

% Taken from
% http://stackoverflow.com/a/17797779/1162884

  %regions = zeros(nVar,2)

  %ax = copy(handle(axesH));

  t = t(:);
  y = y(:);
  stdev = stdev(:);

  lT = numel(t);
  a = zeros(lT,1)+1;

  regions = zeros(1,2);

  regions(1) = patch('XData', [t; t(end:-1:1)], ...
    'YData', [y + 2*stdev; y(end:-1:1)], ...
    'FaceVertexAlphaData',[0*a; a], ...
    'FaceAlpha','interp','EdgeColor','none',...
    'Parent',axesH);

  set(regions(1),'FaceColor',color);

  regions(2) = patch('XData', [t; t(end:-1:1)], ...
    'YData', [y - 2*stdev; y(end:-1:1)], ...
    'FaceVertexAlphaData',[0*a; a], ...
    'FaceColor',color,...
    'FaceAlpha','interp','EdgeColor','none',...
    'Parent',axesH);

  set(regions(2),'FaceColor',color);

  %lnkObj = linkprop([handle(axesH) ax],{'XLim','YLim',...
  %  'Position'});
  %setappdata(ax,'lnkObj',lnkObj);
  %set(ax,'Visible','off')

end

