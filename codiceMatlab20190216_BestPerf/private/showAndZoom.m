function showAndZoom(img,hFig)

    % Demo of how to zoom and pan/scroll the image using a imscrollpanel control.
    format long g;
    format compact;
    fontSize = 13;

    % We introduced IMTOOL and IMSCROLLPANEL, and now there’s more flexibility with the display
    % because the scroll panel shows you that there is more image there beyond what you can see.

    % Have you tried using IMSCROLLPANEL in combination with IMSHOW? See example below or in:
    % doc imscrollpanel
    % 
    % It allows you to directly set the magnification, programmatically or through a magnification box.
    % When we created IMSCROLLPANEL and the associated magnification controls in IPT5, 
    % we hoped that they would satisfy exactly this GUI use case.
    % 
    % Let me know what you think if you try it, or if you've tried it in the past, why it doesn't meet your needs. 
    % We're open to discussing this further with you to see if we can fix the issue or make the better solution easier to discover if it's indeed adequate.
    % Jeff Mather - Image Processing Toolbox developer team leader.

    % Here's the example from the documentation:
    % Create a scroll panel with a Magnification Box and an Overview tool.
    
    hIm = imshow(img);
    hSP = imscrollpanel(hFig,hIm); % Handle to scroll panel.
    set(hSP,'Units', 'normalized',...
            'Position', [0, .1, 1, .9])

    % Add a Magnification Box and an Overview tool.
    hMagBox = immagbox(hFig, hIm);
    boxPosition = get(hMagBox, 'Position');
    set(hMagBox,'Position', [0, 0, boxPosition(3), boxPosition(4)])

    % Get the scroll panel API to programmatically control the view.
    api = iptgetapi(hSP);
    api.setMagnificationAndCenter(1,1,100)
end