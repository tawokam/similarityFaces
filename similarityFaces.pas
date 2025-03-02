  unit similarityFaces;

  interface

  uses
    Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
    Vcl.Controls, Vcl.Forms, Vcl.Dialogs, LuxandFaceSDK, Vcl.StdCtrls, System.Math,  Vcl.Imaging.JPEG,  Vcl.Imaging.PNGImage, System.Types, System.Math.Vectors;

  type
    TForm1 = class(TForm)
      Button1: TButton;
      Button3: TButton;
      procedure Button1Click(Sender: TObject);
      procedure Button2Click(Sender: TObject);
      procedure Button3Click(Sender: TObject);
    private
      { D�clarations priv�es }
    public
      { D�clarations publiques }
    end;

  var
    Form1: TForm1;

  implementation

  {$R *.dfm}

  //--- Conversion de l'image en TBitmap -----------------------------------------
  function LoadAndConvertImage(const FileName: string): TBitmap;
  var
   Graphic : TGraphic;
  begin
    Result := TBitmap.Create;
    try

      IF LowerCase(ExtractFileExt(FileName)) = '.jpg' THEN
        Graphic := TJPEGImage.Create
      ELSE IF LowerCase(ExtractFileExt(FileName)) = '.png' THEN
        Graphic := TPNGImage.Create
      ELSE
        raise Exception.Create('Format d''image non pris en charge');

      try
        Graphic.LoadFromFile(FileName);
        Result.Assign(Graphic);
      finally
        Graphic.Free;
      end;

    except
      Result.Free;
      raise;
    end;
  end;

  //--- Detection du visage sur la photo -----------------------------------------
  function DetectFace(const ImagePath: string; var FaceTemplate: FSDK_FaceTemplate): Boolean;
  var
    res          : Integer;
    Image        : HImage;
    FacePosition : TFacePosition;
    LoadedImage  : TBitmap;
  BEGIN
    //--- Rotation de l'image de 360 degre pour detecter le visage
    //LoadedImage := TBitmap.Create;
    Result := False;

    BEGIN

        //--- Charger l'image ----------------------------------------------------
        LoadedImage := LoadAndConvertImage(ImagePath);

        //--- Charger l'image dans le SDK ----------------------------------------
        res := FSDK_LoadImageFromHBitmap(@Image, LoadedImage.Handle);
        IF res <> FSDKE_OK THEN
        BEGIN
          ShowMessage('�chec du chargement de l''image : ' + ImagePath);
        Exit;
        END;

        //--- Ajuster les param�tres de d�tection des visages --------------------
        FSDK_SetFaceDetectionParameters(True, False, 500);

        //--- D�tecter le visage -------------------------------------------------
        res := FSDK_DetectFace(Image, @FacePosition);
        IF res = FSDKE_OK THEN
        BEGIN

        //--- Cr�er un mod�le de visage ------------------------------------------
         res := FSDK_GetFaceTemplateInRegion(Image, @FacePosition, @FaceTemplate);
          IF res = FSDKE_OK THEN
          BEGIN
            Result := True;
            ShowMessage('Visage d�tect� et mod�le cr�� dans l''image : ' + ImagePath);
          END
          ELSE
          BEGIN
            ShowMessage('�chec de la cr�ation du mod�le de visage dans l''image : ' + ImagePath);
          END;
        END;

    END;
    IF Result = False THEN ShowMessage('Aucun visage d�tect� dans l''image : ' + ImagePath);
    //--- Lib�rer l'image --------------------------------------------------------
    FSDK_FreeImage(Image);
    LoadedImage.Free;
  END;

  // fonction de detection d'un visage
  function DetectFaceInImg(const ImagePath: string): Boolean;
  var
    res          : Integer;
    Image        : HImage;
    FacePosition : TFacePosition;
    LoadedImage  : TBitmap;
    I            : Integer;
    FaceTemplate : FSDK_FaceTemplate;
  BEGIN
    //--- Rotation de l'image de 360 degre pour detecter le visage
    LoadedImage := TBitmap.Create;
    I      := 0;
    Result := False;

    WHILE I <> 360 DO
    BEGIN

        //--- Charger l'image ----------------------------------------------------
        LoadedImage := LoadAndConvertImage(ImagePath);

        //--- Charger l'image dans le SDK ----------------------------------------
        res := FSDK_LoadImageFromHBitmap(@Image, LoadedImage.Handle);
        IF res <> FSDKE_OK THEN
        BEGIN
          ShowMessage('�chec du chargement de l''image : ' + ImagePath);
        Exit;
        END;

        //--- Ajuster les param�tres de d�tection des visages --------------------
        FSDK_SetFaceDetectionParameters(True, False, 500);

        //--- D�tecter le visage -------------------------------------------------
        res := FSDK_DetectFace(Image, @FacePosition);
        IF res = FSDKE_OK THEN
        BEGIN

        //--- Cr�er un mod�le de visage ------------------------------------------
         res := FSDK_GetFaceTemplateInRegion(Image, @FacePosition, @FaceTemplate);
          IF res = FSDKE_OK THEN
          BEGIN
            Result := True;
            ShowMessage('Visage d�tect� et mod�le cr�� dans l''image : ' + ImagePath);
            Break;
          END
          ELSE
          BEGIN
            ShowMessage('�chec de la cr�ation du mod�le de visage dans l''image : ' + ImagePath);
          END;
        END;
      I := I + 90;
    END;
    IF Result = False THEN ShowMessage('Aucun visage d�tect� dans l''image : ' + ImagePath);
    //--- Lib�rer l'image --------------------------------------------------------
    FSDK_FreeImage(Image);
    LoadedImage.Free;
  END;



  function CompareFaces(const ImagePath1, ImagePath2: string): Double;
  var
    FaceTemplate1 : FSDK_FaceTemplate;
    FaceTemplate2 : FSDK_FaceTemplate;
    Similarity    : Single;
  BEGIN
    Result := 0.0;

    //--- Activer la biblioth�que ------------------------------------------------
    IF FSDK_ActivateLibrary('T7tt/sJValWaDkpAeeyeWfQQgptalEQEPa0tH63RF+6J6/yg6PHhp9k7CuKItDsykZz2cQOgVjmbm/Hylts/zPLjwjYbxHvyl3zqq5vWbCTEP+PA5AWztSSW6W3APzfLGayX2dJEhIvwZoWdDx/p1M5p+T/h5APu+NEq4io5dUo=') <> FSDKE_OK THEN
    BEGIN
      ShowMessage('�chec de l''activation.');
      Exit;
    END;

    //--- Initialiser la biblioth�que avec le chemin des fichiers de donn�es -----
    IF FSDK_Initialize('') <> FSDKE_OK THEN
    BEGIN
      ShowMessage('�chec de l''initialisation.');
      Exit;
    END;

    //--- D�tecter les visages et cr�er les mod�les dans les deux images ---------
    IF NOT DetectFace(ImagePath1, FaceTemplate1) THEN
    BEGIN
      ShowMessage('Aucun visage d�tect� dans la premi�re image.');
      Exit;
    END;

    IF NOT DetectFace(ImagePath2, FaceTemplate2) THEN
    BEGIN
      ShowMessage('Aucun visage d�tect� dans la deuxi�me image.');
      Exit;
    END;

    //--- Comparer les visages ---------------------------------------------------
    IF FSDK_MatchFaces(@FaceTemplate1, @FaceTemplate2, @Similarity) = FSDKE_OK THEN
    BEGIN
      //--- Convertir en pourcentage ---------------------------------------------
      Result := Similarity * 100;
      ShowMessage('Comparaison r�ussie. Similarit� : ' + FloatToStr(Ceil(Result)) + '%');
    END
    ELSE
    BEGIN
      ShowMessage('�chec de la comparaison des visages.');
    END;
  END;

  procedure TForm1.Button1Click(Sender: TObject);
  begin
    CompareFaces('C:\Program Files (x86)\Luxand\FaceSDK 8.2.0\demo\IMG1.jpg', 'C:\Program Files (x86)\Luxand\FaceSDK 8.2.0\demo\IMG3.jpg');
  end;

  procedure TForm1.Button2Click(Sender: TObject);
  var
    InputFile  : String;
    Search     : String;
  begin
    InputFile  := 'C:\Program Files (x86)\Luxand\FaceSDK 8.2.0\demo\IMG15.jpg';
    Search     := 'myString';

  end;

  procedure TForm1.Button3Click(Sender: TObject);
  begin
    ShowMessage(DetectFaceInImg('C:\Program Files (x86)\Luxand\FaceSDK 8.2.0\demo\IMG1.jpg').ToString());
  end;

  end.
