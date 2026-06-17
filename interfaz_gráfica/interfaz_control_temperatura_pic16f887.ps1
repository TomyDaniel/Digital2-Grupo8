
# Interfaz grafica TP PIC16F887
# Protocolo:
#   PC  -> PIC: U70 + salto de linea
#   PIC -> PC:  S=70;T=25;R=1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Ports

$baudRate = 9600
$serial = $null
$buffer = ""
$temperaturas = New-Object System.Collections.ArrayList
$maxPuntos = 80

# -------------------------------
# Formulario principal
# -------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "TP PIC16F887 - Control de temperatura"
$form.Size = New-Object System.Drawing.Size(800, 700)
$form.MinimumSize = New-Object System.Drawing.Size(760, 640)
$form.StartPosition = "CenterScreen"

$fontGrande = New-Object System.Drawing.Font("Segoe UI", 24, [System.Drawing.FontStyle]::Bold)
$fontMediana = New-Object System.Drawing.Font("Segoe UI", 11)
$fontNormal = New-Object System.Drawing.Font("Segoe UI", 9)

# -------------------------------
# Conexion serie
# -------------------------------
$grpConexion = New-Object System.Windows.Forms.GroupBox
$grpConexion.Text = "Conexion serie"
$grpConexion.Location = New-Object System.Drawing.Point(12, 10)
$grpConexion.Size = New-Object System.Drawing.Size(760, 70)
$form.Controls.Add($grpConexion)

$lblPuerto = New-Object System.Windows.Forms.Label
$lblPuerto.Text = "Puerto COM:"
$lblPuerto.Location = New-Object System.Drawing.Point(12, 30)
$lblPuerto.Size = New-Object System.Drawing.Size(80, 23)
$grpConexion.Controls.Add($lblPuerto)

$cmbPuertos = New-Object System.Windows.Forms.ComboBox
$cmbPuertos.Location = New-Object System.Drawing.Point(95, 27)
$cmbPuertos.Size = New-Object System.Drawing.Size(120, 25)
$cmbPuertos.DropDownStyle = "DropDownList"
$grpConexion.Controls.Add($cmbPuertos)

$btnActualizar = New-Object System.Windows.Forms.Button
$btnActualizar.Text = "Actualizar"
$btnActualizar.Location = New-Object System.Drawing.Point(225, 25)
$btnActualizar.Size = New-Object System.Drawing.Size(90, 28)
$grpConexion.Controls.Add($btnActualizar)

$btnConectar = New-Object System.Windows.Forms.Button
$btnConectar.Text = "Conectar"
$btnConectar.Location = New-Object System.Drawing.Point(325, 25)
$btnConectar.Size = New-Object System.Drawing.Size(90, 28)
$grpConexion.Controls.Add($btnConectar)

$btnDesconectar = New-Object System.Windows.Forms.Button
$btnDesconectar.Text = "Desconectar"
$btnDesconectar.Location = New-Object System.Drawing.Point(425, 25)
$btnDesconectar.Size = New-Object System.Drawing.Size(100, 28)
$grpConexion.Controls.Add($btnDesconectar)

$lblEstado = New-Object System.Windows.Forms.Label
$lblEstado.Text = "Desconectado"
$lblEstado.Location = New-Object System.Drawing.Point(540, 30)
$lblEstado.Size = New-Object System.Drawing.Size(210, 23)
$grpConexion.Controls.Add($lblEstado)

# -------------------------------
# Enviar setpoint
# -------------------------------
$grpEnvio = New-Object System.Windows.Forms.GroupBox
$grpEnvio.Text = "Enviar setpoint al PIC"
$grpEnvio.Location = New-Object System.Drawing.Point(12, 88)
$grpEnvio.Size = New-Object System.Drawing.Size(760, 70)
$form.Controls.Add($grpEnvio)

$lblSPEnviar = New-Object System.Windows.Forms.Label
$lblSPEnviar.Text = "Setpoint:"
$lblSPEnviar.Location = New-Object System.Drawing.Point(12, 30)
$lblSPEnviar.Size = New-Object System.Drawing.Size(70, 23)
$grpEnvio.Controls.Add($lblSPEnviar)

$txtSetpoint = New-Object System.Windows.Forms.TextBox
$txtSetpoint.Text = "70"
$txtSetpoint.Location = New-Object System.Drawing.Point(85, 27)
$txtSetpoint.Size = New-Object System.Drawing.Size(70, 25)
$grpEnvio.Controls.Add($txtSetpoint)

$btnEnviar = New-Object System.Windows.Forms.Button
$btnEnviar.Text = "Enviar"
$btnEnviar.Location = New-Object System.Drawing.Point(165, 25)
$btnEnviar.Size = New-Object System.Drawing.Size(90, 28)
$grpEnvio.Controls.Add($btnEnviar)

$lblFormato = New-Object System.Windows.Forms.Label
$lblFormato.Text = "Formato enviado: Uxx + salto de linea"
$lblFormato.Location = New-Object System.Drawing.Point(275, 30)
$lblFormato.Size = New-Object System.Drawing.Size(300, 23)
$grpEnvio.Controls.Add($lblFormato)

# -------------------------------
# Tarjetas de datos
# -------------------------------
function Crear-Tarjeta($titulo, $x) {
    $grp = New-Object System.Windows.Forms.GroupBox
    $grp.Text = $titulo
    $grp.Location = New-Object System.Drawing.Point($x, 170)
    $grp.Size = New-Object System.Drawing.Size(240, 105)
    $form.Controls.Add($grp)

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "--"
    $lbl.Font = $fontGrande
    $lbl.TextAlign = "MiddleCenter"
    $lbl.Location = New-Object System.Drawing.Point(10, 28)
    $lbl.Size = New-Object System.Drawing.Size(220, 50)
    $grp.Controls.Add($lbl)

    return $lbl
}

$lblTemp = Crear-Tarjeta "Temperatura sensada (C)" 12
$lblSetpoint = Crear-Tarjeta "Setpoint actual (C)" 272
$lblRelay = Crear-Tarjeta "Relay" 532
$lblRelay.Text = "OFF"

# -------------------------------
# Indicador relay
# -------------------------------
$grpRelay = New-Object System.Windows.Forms.GroupBox
$grpRelay.Text = "Estado del relay"
$grpRelay.Location = New-Object System.Drawing.Point(12, 285)
$grpRelay.Size = New-Object System.Drawing.Size(760, 75)
$form.Controls.Add($grpRelay)

$panelRelay = New-Object System.Windows.Forms.Panel
$panelRelay.Location = New-Object System.Drawing.Point(18, 24)
$panelRelay.Size = New-Object System.Drawing.Size(42, 42)
$panelRelay.BackColor = [System.Drawing.Color]::Gray
$grpRelay.Controls.Add($panelRelay)

$lblRelayTexto = New-Object System.Windows.Forms.Label
$lblRelayTexto.Text = "Relay apagado"
$lblRelayTexto.Font = $fontMediana
$lblRelayTexto.Location = New-Object System.Drawing.Point(78, 32)
$lblRelayTexto.Size = New-Object System.Drawing.Size(400, 25)
$grpRelay.Controls.Add($lblRelayTexto)

# -------------------------------
# Grafico
# -------------------------------
$grpGrafico = New-Object System.Windows.Forms.GroupBox
$grpGrafico.Text = "Temperatura vs tiempo"
$grpGrafico.Location = New-Object System.Drawing.Point(12, 370)
$grpGrafico.Size = New-Object System.Drawing.Size(760, 220)
$form.Controls.Add($grpGrafico)

$panelGrafico = New-Object System.Windows.Forms.Panel
$panelGrafico.Location = New-Object System.Drawing.Point(10, 20)
$panelGrafico.Size = New-Object System.Drawing.Size(740, 190)
$panelGrafico.BackColor = [System.Drawing.Color]::White
$grpGrafico.Controls.Add($panelGrafico)

# -------------------------------
# Ultimo dato
# -------------------------------
$grpDato = New-Object System.Windows.Forms.GroupBox
$grpDato.Text = "Ultimo dato recibido"
$grpDato.Location = New-Object System.Drawing.Point(12, 600)
$grpDato.Size = New-Object System.Drawing.Size(760, 55)
$form.Controls.Add($grpDato)

$lblDato = New-Object System.Windows.Forms.Label
$lblDato.Text = "-"
$lblDato.Location = New-Object System.Drawing.Point(12, 24)
$lblDato.Size = New-Object System.Drawing.Size(730, 23)
$grpDato.Controls.Add($lblDato)

# -------------------------------
# Funciones
# -------------------------------
function Actualizar-Puertos {
    $cmbPuertos.Items.Clear()
    $puertos = [System.IO.Ports.SerialPort]::GetPortNames() | Sort-Object
    foreach ($p in $puertos) {
        [void]$cmbPuertos.Items.Add($p)
    }
    if ($cmbPuertos.Items.Count -gt 0) {
        $cmbPuertos.SelectedIndex = 0
    }
}

function Dibujar-Grafico {
    $bmp = New-Object System.Drawing.Bitmap($panelGrafico.Width, $panelGrafico.Height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::White)

    $penEje = New-Object System.Drawing.Pen([System.Drawing.Color]::Black, 1)
    $penGrilla = New-Object System.Drawing.Pen([System.Drawing.Color]::LightGray, 1)
    $penLinea = New-Object System.Drawing.Pen([System.Drawing.Color]::Blue, 2)

    $x0 = 40
    $y0 = $panelGrafico.Height - 18
    $x1 = $panelGrafico.Width - 10
    $y1 = 8

    $g.DrawLine($penEje, $x0, $y0, $x1, $y0)
    $g.DrawLine($penEje, $x0, $y0, $x0, $y1)

    $fuente = New-Object System.Drawing.Font("Segoe UI", 7)
    $g.DrawString("Eje Y: temperatura (C) de 0 a 100", $fuente, [System.Drawing.Brushes]::Black, [int](($x0 + $x1) / 2 - 80), [int]($panelGrafico.Height - 14))

    for ($t = 0; $t -le 100; $t += 10) {
        $y = $y0 - (($t / 100.0) * ($y0 - $y1))
        $g.DrawLine($penGrilla, $x0, [int]$y, $x1, [int]$y)
        $g.DrawString("$t", $fuente, [System.Drawing.Brushes]::Black, 5, [int]($y - 7))
    }

    if ($temperaturas.Count -gt 1) {
        $pts = New-Object System.Collections.Generic.List[System.Drawing.Point]
        for ($i = 0; $i -lt $temperaturas.Count; $i++) {
            $temp = [int]$temperaturas[$i]
            $x = $x0 + (($i / [double]($maxPuntos - 1)) * ($x1 - $x0))
            $y = $y0 - (($temp / 100.0) * ($y0 - $y1))
            $pts.Add((New-Object System.Drawing.Point([int]$x, [int]$y)))
        }
        if ($pts.Count -gt 1) {
            $g.DrawLines($penLinea, $pts.ToArray())
        }
    }

    $old = $panelGrafico.BackgroundImage
    $panelGrafico.BackgroundImage = $bmp
    if ($old -ne $null) { $old.Dispose() }

    $g.Dispose()
    $penEje.Dispose()
    $penGrilla.Dispose()
    $penLinea.Dispose()
}

function Procesar-Linea($linea) {
    $lblDato.Text = $linea

    if ($linea -match "S=(\d+);T=(\d+);R=(\d+)") {
        $sp = [int]$Matches[1]
        $temp = [int]$Matches[2]
        $relay = [int]$Matches[3]

        $lblSetpoint.Text = "$sp"
        $lblTemp.Text = "$temp"

        if ($relay -eq 1) {
            $lblRelay.Text = "ON"
            $panelRelay.BackColor = [System.Drawing.Color]::LimeGreen
            $lblRelayTexto.Text = "Relay encendido / calentando"
        } else {
            $lblRelay.Text = "OFF"
            $panelRelay.BackColor = [System.Drawing.Color]::Gray
            $lblRelayTexto.Text = "Relay apagado"
        }

        [void]$temperaturas.Add($temp)
        while ($temperaturas.Count -gt $maxPuntos) {
            $temperaturas.RemoveAt(0)
        }

        Dibujar-Grafico
    }
}

# -------------------------------
# Timer de lectura serial
# -------------------------------
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 100

$timer.Add_Tick({
    if ($serial -ne $null -and $serial.IsOpen) {
        try {
            while ($serial.BytesToRead -gt 0) {
                $c = [char]$serial.ReadChar()

                if ($c -eq "`n" -or $c -eq "`r") {
                    $linea = $buffer.Trim()
                    $script:buffer = ""

                    if ($linea.Length -gt 0) {
                        Procesar-Linea $linea
                    }
                } else {
                    $script:buffer += $c

                    if ($script:buffer.Length -gt 80) {
                        $script:buffer = ""
                    }
                }
            }
        } catch {
            $lblEstado.Text = "Error leyendo puerto"
        }
    }
})

# -------------------------------
# Eventos botones
# -------------------------------
$btnActualizar.Add_Click({
    Actualizar-Puertos
})

$btnConectar.Add_Click({
    if ($cmbPuertos.SelectedItem -eq $null) {
        [System.Windows.Forms.MessageBox]::Show("Selecciona un puerto COM.", "Puerto no seleccionado")
        return
    }

    if ($serial -ne $null -and $serial.IsOpen) {
        [System.Windows.Forms.MessageBox]::Show("Ya esta conectado.", "Conexion")
        return
    }

    try {
        $puerto = $cmbPuertos.SelectedItem.ToString()
        $script:serial = New-Object System.IO.Ports.SerialPort($puerto, $baudRate, [System.IO.Ports.Parity]::None, 8, [System.IO.Ports.StopBits]::One)
        $serial.ReadTimeout = 50
        $serial.WriteTimeout = 500
        $serial.Open()

        $lblEstado.Text = "Conectado a $puerto - $baudRate baudios"
        $timer.Start()
    } catch {
        [System.Windows.Forms.MessageBox]::Show("No se pudo abrir el puerto. Cerra Tera Term/LabVIEW si estan abiertos.`n`n$($_.Exception.Message)", "Error de conexion")
    }
})

$btnDesconectar.Add_Click({
    $timer.Stop()
    if ($serial -ne $null) {
        try { $serial.Close() } catch {}
    }
    $script:serial = $null
    $lblEstado.Text = "Desconectado"
})

$btnEnviar.Add_Click({
    if ($serial -eq $null -or -not $serial.IsOpen) {
        [System.Windows.Forms.MessageBox]::Show("Primero conecta el puerto COM.", "Sin conexion")
        return
    }

    $valor = 0
    if (-not [int]::TryParse($txtSetpoint.Text.Trim(), [ref]$valor)) {
        [System.Windows.Forms.MessageBox]::Show("El setpoint tiene que ser un numero entero.", "Valor invalido")
        return
    }

    if ($valor -lt 0 -or $valor -gt 99) {
        [System.Windows.Forms.MessageBox]::Show("Usa un setpoint entre 0 y 99.", "Valor fuera de rango")
        return
    }

    try {
        $serial.Write("U$valor`n")
    } catch {
        [System.Windows.Forms.MessageBox]::Show("No se pudo enviar el setpoint.`n`n$($_.Exception.Message)", "Error de envio")
    }
})

$form.Add_FormClosing({
    $timer.Stop()
    if ($serial -ne $null) {
        try { $serial.Close() } catch {}
    }
})

Actualizar-Puertos
Dibujar-Grafico
[void]$form.ShowDialog()
