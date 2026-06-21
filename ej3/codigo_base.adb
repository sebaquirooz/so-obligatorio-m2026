with Ada.Text_IO; use Ada.Text_IO;
procedure Main is

Dim_X : Integer := 30;
Dim_Y : Integer := 20; --Positive

-- Definimos un nuevo tipo, que hereda el actual
subtype Columnas is Integer range 1 .. Dim_X;
subtype Filas is Integer range 1 .. Dim_Y;

type Screen is array (Columnas, Filas) of Boolean; -- Matriz de bool con dim Dim_X x Dim_Y


task Pantalla is  -- Patio pixel, A: Jugador, B: Bala, C: Nave
   entry Set_Pixel(X: Integer; Y: Integer; Estado: Boolean); -- Prender o apagar pixeles.
   entry Apagar;   
end;
task body Pantalla is 
begin
   Put_Line("En la pantalla");
end Pantalla;

task type Bala is -- Array de balas a disparar (pueden definir una cant max de balas disponibles)
   entry Disparar;
end;
task body Bala is
begin
   -- loop con el mov de la bala.
   -- Hay impacto, se apaga la bala y la nave (id);
   -- Llegas al borde de la pantalla, se muere la bala.

end Bala;

balas : array (1 .. 5) of Bala;


-- El estado compartido del juego.
task Motor;
task body Motor is
begin
end Motor;

procedure Dibujar_Nave(X: Integer; Y: Integer) is -- Naves enemigas (se mueven solas).
begin
end Dibujar_Nave;

procedure Dibujar_Canion is -- Mov izq o der.
begin
end Dibujar_Canion;


Movimiento : Character; -- Cual fue
HayMovimiento : Boolean; -- Aprete una tecla
Continua : Boolean := True;

begin

   loop
      Get_Immediate(Movimiento, HayMovimiento); --Lectura de consola sin bloquear el main;

      if HayMovimiento then
         case Movimiento is
            when 'a' | 'A' =>
               Put_Line("Muevo a la izq.");

            when 'd' | 'D' =>
               Put_Line("Muevo a la der.");
            
            when 'w' | 'W' | ' ' =>
               Put_Line("Disparo!");


            when 'q' | 'Q' =>
               Continua := False;

            when others => -- No hago nada esta ejecutando el juego
               null;
         end case;
      end if;

      delay(0.05);
      Put_Line("Main en loop");

      

      exit when not Continua;
   end loop;

   delay(1.0);

   Put_Line("");
   Put_Line("Termino el juego");
end;