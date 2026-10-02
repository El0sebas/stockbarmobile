// Datos fiscales del emisor (StockBar), espejo de
// stockbar-web/src/data/defaultEmpresa.js — mismo PLACEHOLDER, mismo
// disclaimer: esto no es facturación electrónica DIAN (eso exige
// resolución de numeración autorizada, CUFE, firma digital y validación
// contra la API de la DIAN, fuera del alcance de este frontend sin
// backend). Es un documento de venta con el mismo formato/información que
// exige una factura, para uso interno o como "documento equivalente".
class EmpresaEmisora {
  static const razonSocial = 'StockBar S.A.S.';
  static const nit = '900.000.000-0';
  static const direccion = 'Cra 00 # 00-00, Bogotá D.C.';
  static const telefono = '(601) 000 0000';
  static const regimen = 'Responsable de IVA';
  static const resolucionDian =
      'Documento equivalente de venta — numeración interna (no DIAN)';
}
