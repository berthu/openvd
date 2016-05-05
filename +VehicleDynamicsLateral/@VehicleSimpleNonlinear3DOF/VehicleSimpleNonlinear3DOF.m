%% Nonlinear 3 DOF vehicle model
% Bicycle model nonlinear with 3 degrees of freedom.
%
%% Sintax
% |dx = _VehicleModel_.Model(~,estados)|
%
%% Arguments
% The following table describes the input arguments:
%
% <html> <table border=1 width="97%">
% <tr> <td width="30%"><tt>estados</tt></td> <td width="70%">Estados do modelo: [dPSI ALPHAT PSI XT YT VEL]</td> </tr>
% </table> </html>
%
%% Description
% O centro de massa do ve�culo � dado pelo ponto $T$ e os eixos dianteiro e traseiro s�o dados pelos pontos $F$ e $R$, respectivamente. A constante $a$ mede a dist�ncia do ponto $F$ ao $T$ e $b$ a dist�ncia do ponto $T$ ao $R$. Os �ngulos $\alpha_F$ e $\alpha_R$ s�o os �ngulos de deriva nos eixos dianteiro e traseiro. $\alpha_T$ is the vehicle side slip angle and $\psi$ is the vehicle yaw angle. Por fim, $\delta$ � o �ngulo de ester�amento.
%
% <<illustrations/modeloSimples.svg>>
%
%% Code
%

classdef VehicleSimpleNonlinear3DOF < VehicleDynamicsLateral.VehicleSimple
	methods
        % Constructor
        function self = VehicleSimpleNonlinear3DOF(IT, lf, lr, mF0, mR0, deltaf, lT, nF, nR, wT, muy, tire)
	        self.IT = IT;                          % Moment of inertia [kg*m2]
	        self.lf = lf;                          % [m]
	        self.lr = lr;                          % [m]

			self.mT = self.mF0 + self.mR0;         % Vehicle total mass [kg]
	        self.a = self.mR0 / self.mT * self.lT; % [m]
	        self.b = self.lT - self.a;             % [m]

	        self.mF0 = lr * m / (lf + lr);         % Mass @ F [kg]
	        self.mR0 = lf * m / (lf + lr);         % Mass @ R [kg]
	        self.deltaf = 0;                       % Steering angle [rad]
	        self.lT = lf + lr;                     % [m]

	        self.nF = nR;                          % Number of tires @ F
	        self.nR = nF;                          % Number of tires @ R
	        self.wT = wT;                          % Width [m]
	        self.muy = muy;                        % Operational friction coefficient

	        self.params = [mF0 mR0 IT DELTA lT nF nR largT muy mT a b];
	        self.tire = tire;
        end

        %% Model
        % Fun��o com as equa��es de estado do modelo
        function dx = Model(self, ~, estados)
			% Data
            m = self.mT;              % Vehicle total mass [kg]
            I = self.IT;              % Moment of inertia [kg]
            a = self.a;               % [m]
            b = self.b;               % [m]
            nF = self.nF;             % Number of tires @ F
            nR = self.nR;             % Number of tires @ R
            muy = self.muy;           % Operational friction coefficient
            DELTA = self.deltaf;

			g = 9.81;                 % Acelera��o da gravidade [m/s^2]

            FzF = self.mF0 * g;       % Vertical load @ F [N]
            FzR = self.mR0 * g;       % Vertical load @ R [N]

            % Estados
            dPSI = estados(1);
            ALPHAT = estados(2);
            v = estados(6);
            PSI = estados(3);

            % Angulos de deriva n�o linear
            ALPHAF = atan2((v * sin(ALPHAT) + a * dPSI), (v * cos(ALPHAT))) - DELTA; % Dianteiro
            ALPHAR = atan2((v * sin(ALPHAT) - b * dPSI), (v * cos(ALPHAT)));         % Traseiro

            % For�as longitudinais
            FxF = 0;
            FxR = 0;

            % Curva caracter�stica
            FyF = nF*self.tire.Characteristic(ALPHAF,FzF/nF,muy);
            FyR = nR*self.tire.Characteristic(ALPHAR,FzR/nR,muy);

            % Equa��es de estado
            dx(1,1) = (FyF*a*cos(DELTA) - FyR*b + FxF*a*sin(DELTA))/I;
            dx(2,1) = (FyR + FyF*cos(DELTA) + FxF*sin(DELTA) - m*(dPSI*v*cos(ALPHAT) + (sin(ALPHAT)*(FxR + 	FxF*cos(DELTA) - FyF*sin(DELTA) +...
                      dPSI*m*v*sin(ALPHAT)))/(m*cos(ALPHAT))))/(m*(v*cos(ALPHAT) + (v*sin(ALPHAT)^2)/cos(ALPHAT)));
            dx(6,1) = (FxR*cos(ALPHAT) + FyR*sin(ALPHAT) - FyF*cos(ALPHAT)*sin(DELTA) + FyF*cos(DELTA)*sin(ALPHAT) + ...
                      FxF*sin(ALPHAT)*sin(DELTA) + FxF*cos(ALPHAT)*cos(DELTA))/(m*cos(ALPHAT)^2 + m*sin(ALPHAT)^2);

            % Obten��o da orienta��o
            dx(3,1) = dPSI; % dPSI

            % Equa��es adicionais para o posicionamento (N�o necess�rias para a din�mica em guinada)
            dx(4,1) = v*cos(ALPHAT + PSI); % X
            dx(5,1) = v*sin(ALPHAT + PSI); % Y
        end
    end
end

%% See Also
%
% <index.html Index> | <VehicleArticulatedNonlinear4DOF.html VehicleArticulatedNonlinear4DOF>
%
