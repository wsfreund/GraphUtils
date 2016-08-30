function out = colorGradient(color1,varargin)
%
%   grandient = colorGradient(color1,color2,...,colorN,nSteps): Create
% gradient color ending in the first color and starting at last
% input color. If only one color is specified, it will start at
% white and change linearly using nSteps until color1).
%
%   The nSteps argument is an array of length N-1, used to define the
% number of gradients to be used while changing from the color colorK
% to colorK-1, where k is a natural number from 2 to N. You can also
% specify it as a unique number, which will be applied for each
% different color.
%
%     grandient = colorGradient(color1,color2,...,colorN,nSteps,...
%    'Smoothing','on'): Create color spectrum using the color bases,
%   but smooths the maximum distance between colors as 40%
%
%     grandient = colorGradient(color1,color2,...,colorN,nSteps,...
%  'Smoothing','on','SmoothThres',value): As before, but specify
%  color step maximum threshold to value.
%
%   If only one step is used, the end color is returned.
%

% - Creation Date: Sun, 08 Sep 2013 
% - Last Modified: Fri, 22 Aug 2014
% - Author(s): 
%   - W.S.Freund <wsfreund_at_gmail_dot_com> 

  if nargin<2
    Output.ERROR(...
      'NILM_CEPEL:GraphUtils:colorGradient:WrongInputs',...
      ['At least one color and the number of steps to use'...
      ' must be specified.']);
  end

  smoothing = false;
  smoothThres = .4;

  if numel(varargin)>2
    inputSmoothIdx=find(cellfun(@(in) strcmp(in,'Smoothing'),...
      varargin),1);
    if ~isempty(inputSmoothIdx)
      switch varargin{inputSmoothIdx+1}
      case 'on'
        smoothing = true;
      case 'off'
        smoothing = false;
      otherwise 
        smoothing = varargin{inputSmoothIdx+1};
      end
      varargin(inputSmoothIdx:inputSmoothIdx+1) = [];
    end
    inputSmoothThresIdx=find(cellfun(@(in) strcmp(in,'SmoothThres'),...
      varargin),1);
    if ~isempty(inputSmoothThresIdx)
      smoothThres = varargin{inputSmoothThresIdx+1};
      varargin(inputSmoothThresIdx:inputSmoothThresIdx+1) = [];
    end
  end


  steps = varargin{end};

  if  numel(varargin)>1
    colors = [flipud(checkColor(varargin(1:end-1)));...
      checkColor(color1)];
  else 
    colors = [.9 .9 .9;checkColor(color1)];
  end

  nSteps = numel(steps);

  if nSteps==1
    steps = repmat(steps,1,size(colors,1)-1);
    nSteps = numel(steps);
  end

  if nSteps~=size(colors,1)-1
    Output.ERROR(...
      'NILM_CEPEL:GraphUtils:colorGradient:WrongInputs',...
      ['The number of steps to use must be an array containing'...
      ' the number of shades to use in between the colorK to'...
      ' colorK-1. It''s size must be of length N-1.']);
  end

  out = zeros(sum(steps),3);

  colorsFilled = 0;

  for curStepIdx = 1:nSteps
    if curStepIdx>1
      curStep = steps(curStepIdx)+1;
    else
      curStep = steps(curStepIdx);
    end

    % Apply smoothing so that the colors gradient is not too high:
    if smoothing
      deltas = colors(curStepIdx+1,:)-colors(curStepIdx,:);
      deltasSum = sum(abs(deltas));
      if deltasSum/curStep>smoothThres
        if colorsFilled
          colors(curStepIdx+1,:) = out(colorsFilled,:) + ...
            deltas*smoothThres*curStep/deltasSum;
        else
          colors(curStepIdx+1,:) = colors(curStepIdx,:) + ...
            deltas*smoothThres*curStep/deltasSum;
        end
      end
    end

    out(colorsFilled+1:colorsFilled+curStep,:) = reshape(...
      [linspace(colors(curStepIdx,1),colors(curStepIdx+1,1),curStep),...
       linspace(colors(curStepIdx,2),colors(curStepIdx+1,2),curStep),...
       linspace(colors(curStepIdx,3),colors(curStepIdx+1,3),curStep)],...
       curStep,3);
    if curStepIdx>1
      out(colorsFilled+1,:) = [];
    end
    colorsFilled = colorsFilled + steps(curStepIdx);
  end

end

function outColor = checkColor(color)
  if ~iscell(color)
    color = {color};
  end
  nColors = numel(color);
  outColor = zeros(nColors,3);
  for k=1:nColors
    curColor = color{k};
    if ischar(curColor)
      switch curColor
      case {'r','red'}
        outColor(k,:) = [1 0 0];
      case {'g','green'}
        outColor(k,:) = [0 1 0];
      case {'b','blue'}
        outColor(k,:) = [0 0 1];
      case {'c','cyan'}
        outColor(k,:) = [0 1 1];
      case {'m','magenta'}
        outColor(k,:) = [1 0 1];
      case {'y','yellow'}
        outColor(k,:) = [1 1 0];
      case {'k','black'}
        outColor(k,:) = [1 1 1];
      case {'w','white'}
        outColor(k,:) = [0 0 0];
      otherwise
        Output.ERROR(...
          'NILM_CEPEL:GraphUtils:colorGradient:WrongInputs',...
          ['Inputs should be the basics color name or specified.'...
          ' Unknown color name: %s'],curColor);
      end
    elseif isnumeric(curColor) && numel(curColor) == 3
      outColor(k,:) = curColor;
    else
      Output.ERROR(...
        'NILM_CEPEL:GraphUtils:colorGradient:WrongInputs',...
        ['You should specify color using basic color names or'...
        ' the color spectrum at rgb, i.e: [1 0 0] for red.']);
    end
  end
end
