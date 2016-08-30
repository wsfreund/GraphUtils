function [bool,axesLine,axesColumn] = isOverAxes(figH,axesH,method)
%
% Package NILM_CEPEL.GraphUtils: Function setCustomPlotArea
% Check if pointer is inbound axes.
%
% [bool,axesLine,axesColumn] = GraphUtils.isOverAxes(figH,axesH)
%
%                         ------  Inputs  -------
%
% -> figH (figure handle): figure handle
%
% -> axesH (axes handle): axes handle in matrix form, lines and
% columns matching the figure display.
%
% -> method (int):
%  - 0, use figure current point (for mouse push buttons)
%
%  - 1, use root current point (for mouse movimentation without
%  pushing)
% 

% - Creation Date: Thu, 05 Sep 2013
% - Last Modified: Sun, 10 Aug 2014
% - Author(s): 
%   - W.S.Freund <wsfreund_at_gmail_dot_com>

% Inspired by dtmcursor
% http://www.mathworks.com/matlabcentral/fileexchange/42675-dtmcursor

% FIXME Re-order the current axis so that they are on the expected
% order (as the latin write direction)

  try
    if nargin < 3
      method = 0;
    end
    switch method
    case 0
      oldUnits=get(figH,'units');
      set(figH,'units','normalized');
      cp = get(figH,'CurrentPoint');
      for axesColumn=1:size(axesH,2)
        for axesLine=1:size(axesH,1)
          oldAxesUnits=get(axesH(axesLine,axesColumn),'Units');
          set(axesH(axesLine,axesColumn),'Units','normalized');
          axpos = get(axesH(axesLine,axesColumn),'position');
          set(axesH(axesLine,axesColumn),'Units',oldAxesUnits);
          axlim = axpos(1) + axpos(3);
          aylim = axpos(2) + axpos(4);
          bool = true;
          if or(cp(1) > (axlim+.01), cp(1) < (axpos(1)-.01))
            bool = false;
          elseif or(cp(2) > (aylim+.01), cp(2) < (axpos(2)-.01))
            bool = false;
          end
          if bool
            break;
          end
        end
        if bool
          break;
        end
      end
      set(figH,'units',oldUnits);
    case 1
      % First check if the click was inside the figure:
      oldUnits=get(0,'Units');
      set(0,'Units','normalized');
      cp = get(0,'PointerLocation');
      set(0,'Units',oldUnits);
      oldUnits=get(gcf,'Units');
      set(gcf,'Units','normalized');
      pos = get(gcf,'Position');
      set(gcf,'Units',oldUnits);
      cpOnFig(2) = (cp(2)-pos(2))/pos(4);
      cpOnFig(1) = (cp(1)-pos(1))/pos(3);
      if any(cpOnFig>1) || any(cpOnFig<0)
        % Click outside the figure:
        bool = false;
        axesLine = [];
        axesColumn = [];
        return
      end
      % Now that we now if the click was inside the figure, check if
      % it was inside one of the axis:
      for axesColumn=1:size(axesH,2)
        for axesLine=1:size(axesH,1)
          if ~axesH(axesLine,axesColumn)
            continue
          end
          oldAxesUnits=get(axesH(axesLine,axesColumn),'Units');
          set(axesH(axesLine,axesColumn),'Units','normalized');
          axpos = get(axesH(axesLine,axesColumn),'position');
          set(axesH(axesLine,axesColumn),'Units',oldAxesUnits);
          axlim = axpos(1) + axpos(3);
          aylim = axpos(2) + axpos(4);
          bool = true;
          if or(cpOnFig(1) > (axlim-.01), cpOnFig(1) < (axpos(1)-.01))
            bool = false;
          elseif or(cpOnFig(2) > (aylim-.01), cpOnFig(2) < (axpos(2)-.01))
            bool = false;
          end
          if bool
            break;
          end
        end
        if bool
          break;
        end
      end
    end
  catch ext
    Output.WARNING(['NILM_CEPEL:GraphUtils:isOverAxes'],...
      ['Could not check if mouse is inside axes'...
      ' position. Reason:\n' ext.getReport]);
    bool = false;
    axesLine = [];
    axesColumn = [];
  end
end % function


