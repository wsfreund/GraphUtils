function pos = getObjectPos(curHor,curVert,nHorObjs,nVertObjs,...
  horGap,vertGap,opt)
%
% Package NILM_CEPEL.GraphUtils: Function getObjectPos
%   Create position for current object creating evenly separeted objects.
%
%                         ------  Inputs  -------
%
% -> curHor (int): current object horizontal index.
%
% -> currVert (int): current object vertical index.
%
% -> nHorObjs (int): number of objects on horizontal.
%
% -> nVertObjs (int): number of objects on vertical.
%
% -> horGap <.02> (double): horizontal gap space between currrent
% object and the border.
%
% -> vertGap <.02> (double): vertical gap space between current object
% and the border.
%
% -> opts <'absolut'> 

% - Creation Date: Thu, 05 Sep 2013
% - Last Modified: Sun, 10 Aug 2014
% - Author(s): 
%   - W.S.Freund <wsfreund_at_gmail_dot_com>

  if nargin < 7
    opt = 'rel';
    if nargin < 6
      vertGap = .02;
      if nargin < 5
        horGap = .02;
      end
    end
  end

  curHor=double(curHor);curVert=double(curVert);
  nHorObjs=double(nHorObjs);
  nVertObjs=double(nVertObjs);horGap=double(horGap);
  vertGap=double(vertGap);
  if numel(curHor)>2 || numel(curVert)>2
    Output.ERROR(...
      'NILM_CEPEL:GraphUtils:getObjectPos:WrongInputs',...
      ['Object must occupy continuous region blocks. I.e.: [1 2],'...
      '[2 3],[1 4],[1 1],[2],...']);
  end
  startHorPos = curHor(1);
  startVertPos = curVert(1);
  if numel(curHor)==2
    endHorPos = curHor(2);
  else
    endHorPos = curHor(1);
  end
  if numel(curVert)==2
    endVertPos = curVert(2);
  else
    endVertPos = curVert(1);
  end
  nHor = endHorPos - startHorPos + 1;
  nVert = endVertPos - startVertPos + 1;
  pos = zeros(1,4);
  fullObjWidth = 1/nHorObjs;
  fullObjHeigth = 1/nVertObjs;
  switch opt
  case 'rel'
    pos(3) = (1-horGap)*fullObjWidth*nHor;
    pos(4) = (1-vertGap)*fullObjHeigth*nVert;
    pos(1) = ( horGap/2*nHor + (startHorPos-1)) * ...
      fullObjWidth;
    pos(2) = 1 + ( vertGap/2*nVert - endVertPos) * ...
      fullObjHeigth;
  case 'abs'
    pos(3) = fullObjWidth*nHor-horGap;
    pos(4) = fullObjHeigth*nVert-vertGap;
    pos(1) = horGap/2 + (startHorPos-1) * ...
      fullObjWidth;
    pos(2) = 1 + vertGap/2 - endVertPos * ...
      fullObjHeigth;
  end
end
