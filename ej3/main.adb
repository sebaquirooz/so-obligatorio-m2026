with Ada.Text_IO; use Ada.Text_IO;

procedure Main is

   Dim_X : constant Integer := 80;
   Dim_Y : constant Integer := 24;

   Nave_Ancho : constant Integer := 2;
   Nave_Alto  : constant Integer := 2;

   Cantidad_Naves : constant Integer := 10;
   Cantidad_Balas : constant Integer := 5;

   subtype Columnas is Integer range 1 .. Dim_X;
   subtype Filas is Integer range 1 .. Dim_Y;

   type Screen is array (Filas, Columnas) of Character;

   task Pantalla is
      entry Limpiar;
      entry Set_Pixel (X : Integer; Y : Integer; Simbolo : Character);
      entry Dibujar;
      entry Apagar;
   end Pantalla;

   task body Pantalla is
      Buffer : Screen;
      Terminar : Boolean := False;

      procedure Vaciar is
      begin
         for Y in Filas loop
            for X in Columnas loop
               Buffer (Y, X) := ' ';
            end loop;
         end loop;
      end Vaciar;

   begin
      Vaciar;

      loop
         select
            accept Limpiar do
               Vaciar;
            end Limpiar;

         or
            accept Set_Pixel (X : Integer; Y : Integer; Simbolo : Character) do
               if X >= Columnas'First and X <= Columnas'Last and
                  Y >= Filas'First and Y <= Filas'Last
               then
                  Buffer (Y, X) := Simbolo;
               end if;
            end Set_Pixel;

         or
            accept Dibujar do
               Put (Character'Val (27) & "[2J");
               Put (Character'Val (27) & "[H");

               for Y in Filas loop
                  declare
                     Linea : String (1 .. Dim_X);
                  begin
                     for X in Columnas loop
                        Linea (X) := Buffer (Y, X);
                     end loop;

                     Put_Line (Linea);
                  end;
               end loop;
            end Dibujar;

         or
            accept Apagar do
               Terminar := True;
            end Apagar;
         end select;

         exit when Terminar;
      end loop;
   end Pantalla;

   task Motor is
      entry Nave_Destruida;
      entry Consultar_Vivas (Vivas : out Integer);
      entry Consultar_Fin (Termino : out Boolean);
      entry Apagar;
   end Motor;

   task body Motor is
      Naves_Vivas : Integer := Cantidad_Naves;
      Terminar : Boolean := False;
   begin
      loop
         select
            accept Nave_Destruida do
               if Naves_Vivas > 0 then
                  Naves_Vivas := Naves_Vivas - 1;
               end if;
            end Nave_Destruida;

         or
            accept Consultar_Vivas (Vivas : out Integer) do
               Vivas := Naves_Vivas;
            end Consultar_Vivas;

         or
            accept Consultar_Fin (Termino : out Boolean) do
               Termino := Naves_Vivas = 0;
            end Consultar_Fin;

         or
            accept Apagar do
               Terminar := True;
            end Apagar;
         end select;

         exit when Terminar;
      end loop;
   end Motor;

   task type Nave is
      entry Configurar (Numero : Integer; X : Integer; Y : Integer);
      entry Consultar (X : out Integer; Y : out Integer; Viva : out Boolean);
      entry Impactar (Bala_X : Integer; Bala_Y : Integer; Hubo_Impacto : out Boolean);
      entry Apagar;
   end Nave;

   task body Nave is
      ID : Integer := 0;
      Pos_X : Integer := 1;
      Pos_Y : Integer := 1;
      Esta_Viva : Boolean := True;
      Direccion : Integer := 1;
      Terminar : Boolean := False;
      Avisar_Destruccion : Boolean := False;
      Ciclos_Movimiento : Integer := 0;

      procedure Mover is
      begin
         if Esta_Viva then
            if Pos_X <= 1 then
               Direccion := 1;
            elsif Pos_X + Nave_Ancho - 1 >= Dim_X then
               Direccion := -1;
            end if;

            Pos_X := Pos_X + Direccion;
         end if;
      end Mover;

      function Hay_Colision (Bala_X : Integer; Bala_Y : Integer) return Boolean is
      begin
         return Esta_Viva and then
            Bala_X >= Pos_X and then Bala_X <= Pos_X + Nave_Ancho - 1 and then
            Bala_Y >= Pos_Y and then Bala_Y <= Pos_Y + Nave_Alto - 1;
      end Hay_Colision;

   begin
      accept Configurar (Numero : Integer; X : Integer; Y : Integer) do
         ID := Numero;
         Pos_X := X;
         Pos_Y := Y;
      end Configurar;

      loop
         select
            accept Consultar (X : out Integer; Y : out Integer; Viva : out Boolean) do
               X := Pos_X;
               Y := Pos_Y;
               Viva := Esta_Viva;
            end Consultar;

         or
            accept Impactar (Bala_X : Integer; Bala_Y : Integer; Hubo_Impacto : out Boolean) do
               if Hay_Colision (Bala_X, Bala_Y) then
                  Esta_Viva := False;
                  Hubo_Impacto := True;
                  Avisar_Destruccion := True;
               else
                  Hubo_Impacto := False;
               end if;
            end Impactar;

         or
            accept Apagar do
               Terminar := True;
            end Apagar;

         or
            delay 0.01;
         end select;

         if Avisar_Destruccion then
            Motor.Nave_Destruida;
            Avisar_Destruccion := False;
         end if;

         Ciclos_Movimiento := Ciclos_Movimiento + 1;

         if Ciclos_Movimiento >= 100 then
            Mover;
            Ciclos_Movimiento := 0;
         end if;

         exit when Terminar;
      end loop;
   end Nave;

   Naves : array (1 .. Cantidad_Naves) of Nave;

   task type Bala is
      entry Disparar (X : Integer; Y : Integer; Aceptada : out Boolean);
      entry Consultar (X : out Integer; Y : out Integer; Activa : out Boolean);
      entry Apagar;
   end Bala;

   task body Bala is
      Pos_X : Integer := 1;
      Pos_Y : Integer := 1;
      Esta_Activa : Boolean := False;
      Terminar : Boolean := False;
      Ciclos_Movimiento : Integer := 0;

      procedure Revisar_Colisiones is
         Impacto : Boolean := False;
      begin
         if Esta_Activa then
            for I in Naves'Range loop
               Naves (I).Impactar (Pos_X, Pos_Y, Impacto);

               if Impacto then
                  Esta_Activa := False;
                  exit;
               end if;
            end loop;
         end if;
      end Revisar_Colisiones;

      procedure Avanzar is
      begin
         if Esta_Activa then
            Pos_Y := Pos_Y - 1;

            if Pos_Y < 1 then
               Esta_Activa := False;
            else
               Revisar_Colisiones;
            end if;
         end if;
      end Avanzar;

   begin
      loop
         select
            accept Disparar (X : Integer; Y : Integer; Aceptada : out Boolean) do
               if Esta_Activa then
                  Aceptada := False;
               else
                  Pos_X := X;
                  Pos_Y := Y;
                  Esta_Activa := True;
                  Aceptada := True;
               end if;
            end Disparar;

         or
            accept Consultar (X : out Integer; Y : out Integer; Activa : out Boolean) do
               X := Pos_X;
               Y := Pos_Y;
               Activa := Esta_Activa;
            end Consultar;

         or
            accept Apagar do
               Terminar := True;
            end Apagar;

         or
            delay 0.01;
         end select;

         if Esta_Activa then
            Ciclos_Movimiento := Ciclos_Movimiento + 1;

            if Ciclos_Movimiento >= 4 then
               Avanzar;
               Ciclos_Movimiento := 0;
            end if;
         else
            Ciclos_Movimiento := 0;
         end if;

         exit when Terminar;
      end loop;
   end Bala;

   Balas : array (1 .. Cantidad_Balas) of Bala;

   procedure Dibujar_Nave (X : Integer; Y : Integer) is
   begin
      Pantalla.Set_Pixel (X,     Y,     'M');
      Pantalla.Set_Pixel (X + 1, Y,     'M');
      Pantalla.Set_Pixel (X,     Y + 1, 'M');
      Pantalla.Set_Pixel (X + 1, Y + 1, 'M');
   end Dibujar_Nave;

   procedure Dibujar_Canion (X : Integer) is
      Y : constant Integer := Dim_Y - 1;
   begin
      Pantalla.Set_Pixel (X,     Y,     'A');
      Pantalla.Set_Pixel (X + 1, Y,     'A');
      Pantalla.Set_Pixel (X,     Y + 1, 'A');
      Pantalla.Set_Pixel (X + 1, Y + 1, 'A');
   end Dibujar_Canion;

   procedure Dibujar_Bala (X : Integer; Y : Integer) is
   begin
      Pantalla.Set_Pixel (X, Y, '|');
   end Dibujar_Bala;

   procedure Disparar_Bala (Canon_X : Integer) is
      Aceptada : Boolean := False;
      Bala_X : constant Integer := Canon_X + 1;
      Bala_Y : constant Integer := Dim_Y - 2;
   begin
      for I in Balas'Range loop
         Balas (I).Disparar (Bala_X, Bala_Y, Aceptada);

         exit when Aceptada;
      end loop;
   end Disparar_Bala;

   procedure Redibujar (Canon_X : Integer) is
      X : Integer;
      Y : Integer;
      Vivas : Integer;
      Viva : Boolean;
      Activa : Boolean;
   begin
      Pantalla.Limpiar;

      for I in Naves'Range loop
         Naves (I).Consultar (X, Y, Viva);

         if Viva then
            Dibujar_Nave (X, Y);
         end if;
      end loop;

      for I in Balas'Range loop
         Balas (I).Consultar (X, Y, Activa);

         if Activa then
            Dibujar_Bala (X, Y);
         end if;
      end loop;

      Dibujar_Canion (Canon_X);
      Pantalla.Dibujar;
      Motor.Consultar_Vivas (Vivas);
      Put_Line ("Naves restantes:" & Integer'Image (Vivas));
   end Redibujar;

   Movimiento : Character;
   Hay_Movimiento : Boolean;
   Continua : Boolean := True;
   Juego_Terminado : Boolean := False;
   Canon_X : Integer := Dim_X / 2;

begin
   Put_Line ("A: izquierda | D: derecha | W o espacio: disparar | Q: salir");
   delay 1.0;

   for I in Naves'Range loop
      declare
         Columna : constant Integer := 5 + ((I - 1) mod 5) * 12;
         Fila : constant Integer := 2 + ((I - 1) / 5) * 4;
         Offset : constant Integer := ((I - 1) / 5) * 4;
      begin
         Naves (I).Configurar (I, Columna + Offset, Fila);
      end;
   end loop;

   loop
      Get_Immediate (Movimiento, Hay_Movimiento);

      if Hay_Movimiento then
         case Movimiento is
            when 'a' | 'A' =>
               if Canon_X > 1 then
                  Canon_X := Canon_X - 1;
               end if;

            when 'd' | 'D' =>
               if Canon_X + Nave_Ancho - 1 < Dim_X then
                  Canon_X := Canon_X + 1;
               end if;

            when 'w' | 'W' | ' ' =>
               Disparar_Bala (Canon_X);

            when 'q' | 'Q' =>
               Continua := False;

            when others =>
               null;
         end case;
      end if;

      Redibujar (Canon_X);
      Motor.Consultar_Fin (Juego_Terminado);

      exit when not Continua or else Juego_Terminado;

      delay 0.05;
   end loop;

   for I in Balas'Range loop
      Balas (I).Apagar;
   end loop;

   for I in Naves'Range loop
      Naves (I).Apagar;
   end loop;

   Motor.Apagar;
   Pantalla.Apagar;

   Put_Line ("");

   if Juego_Terminado then
      Put_Line ("Ganaste: no quedan naves enemigas.");
   else
      Put_Line ("Termino el juego.");
   end if;
end Main;
