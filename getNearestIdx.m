function vIdx = getNearestIdx(values,point)
%
% Package NILM_CEPEL.GraphUtils: Function getNearestIdx
%   Get the nearest index from a point at the values same distanced
% stochastic array.
%
% vIdx = getNearestIdx(values,point)
%
%                         ------  Inputs  -------
%
% -> values: the array to find the closiest index, it must be a equal
% step array.
%
% -> point: the point to be found the neareast at the array.
%
%                         ------  Outputs  -------
%  
% -> vIdx: the index on values. If no index inbound, returns an empty
% array.
%

% Based on:
% http://stackoverflow.com/questions/18349081/minimization-of-convex-stochastic-values

% - Creation Date: Thu, 05 Sep 2013
% - Last Modified: Sun, 10 Aug 2014
% - Author(s): 
%   - W.S.Freund <wsfreund_at_gmail_dot_com>

if isempty(values) || ~numel(values)
  vIdx = [];
  return
end


vIdx = 1+round((point-values(1))*(numel(values)-1)...
  /(values(end)-values(1)));
if vIdx < 1, vIdx = []; end
if vIdx > numel(values), vIdx = []; end
end
