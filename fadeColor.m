function fadedColor = fadeColor(color)
%
% TODO Help
%

% - Creation Date: Mon, 21 Oct 2013
% - Last Modified: Sun, 10 Aug 2014
% - Author(s): 
%   - W.S.Freund <wsfreund_at_gmail_dot_com> 

  fadedColor = GraphUtils...
    .colorGradient(color,[1 1 1],1,...
    'Smoothing',true,'SmoothThres',.9);
  if sum([1 1 1]-fadedColor)<.6
    % Fade to Black \,,/
    fadedColor = GraphUtils...
      .colorGradient(color,[0 0 0],1,...
      'Smoothing',true,'SmoothThres',.9);
  end

end

