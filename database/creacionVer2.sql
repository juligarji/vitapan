SET FOREIGN_KEY_CHECKS=0;
drop table if exists PROVEEDOR; /* ********** */
drop table if exists VENDEDOR_PRECIO; /* ********** */
drop table if exists ITEM_VENTA;/* ********** */  
drop table if exists INVENTARIO_PAN;/* ********** */  
drop table if exists PEDIDO;/* ********** */ 
drop table if exists ITEM_PEDIDO;/* ********** */ 
drop table if exists INVENTARIO_MATERIA_PRIMA;/* &&&&&&&&&& */ 
drop table if exists CREACION;/* &&&&&&&&&& */ 
drop table if exists PRODUCCION;/* &&&&&&&&&& */ 
drop table if exists RECETA;/* &&&&&&&&&& */ 
drop table if exists ITEM_RECETA;/* &&&&&&&&&& */ 
drop table if exists CONTRATO;/* &&&&&&&&&& */ 

drop table if exists ITEM_DEVOLUCION;
drop table if exists ITEM_DESPACHO;
drop table if exists BANCO;
drop table if exists REGISTRO_DIA;
drop table if exists BUFFER_REG_DIA;
drop table if exists INGRESO;


drop table if exists ITEM_CONTRATO;/* &&&&&&&&&& */ 
drop table if exists NOMINA;/* &&&&&&&&&& */ 
drop table if exists CAJA;/* &&&&&&&&&& */ 
drop table if exists DEUDA;/* &&&&&&&&&& */ 
drop table if exists DEUDA_PAGADA;/* &&&&&&&&&& */ 
drop table if exists GASTO;/* &&&&&&&&&& */ 
drop table if exists ITEM_GASTO;/* &&&&&&&&&& */ 
drop table if exists COBRAR;/* &&&&&&&&&& */ 
drop table if exists ITEM_COBRAR;/* &&&&&&&&&& */ 
drop table if exists MOJE; /* &&&&&&&&&& */ 

 drop table if exists EMPLEADO; /* ********** */
 drop table if exists VENDEDOR; /* ********** */

 drop table if exists EMPLEADO_CARGO; /* ********** */


drop table if exists VENTA;/* ********** */

drop table if exists RUTA; /* ********** */

drop table if exists CLIENTE; /* ********** */
drop table if exists CLIENTE_ESPECIAL;/* ********** */



drop table if exists PAQUETE;/* ********** */
drop table if exists PAN;/* ********** */
drop table if exists PAN_CATEGORIA;/* ********** */


drop table if exists MATERIA_PRIMA;/* ********** */
drop table if exists MATERIA_PRIMA_CATEGORIA;/* ********** */
drop table if exists UNIDAD_MEDIDA;/* ********** */

drop table if exists USUARIO;


 


create table EMPLEADO_CARGO(-- creado bien
	EMP_CAR_nombre varchar(15) not null,
	EMP_CAR_permisos int not null,
	primary key(EMP_CAR_nombre)
);

create table EMPLEADO(-- creado bien
		EMP_code int not null auto_increment,
		EMP_nombre varchar(30) not null,
		EMP_apellido varchar(30) not null,
		EMP_cedula bigint(17) not null,
		EMP_fechaNac date not null,
		EMP_telefono bigint(17) not null,
		EMP_direccion varchar(45),
		EMP_email varchar(45),
		EMP_idCargo varchar(15) not null,
		EMP_horaEntra datetime not null,
		EMP_horaSalida datetime,
		/*EMP_idContrato varchar(15) not null,*/
		EMP_salario int not null,

		primary key (EMP_code),
		foreign key (EMP_idCargo) references EMPLEADO_CARGO(EMP_CAR_nombre)
		/*foreign key (EMP_idContrato) references CONTRATO(CON_nombre),*/
);


create table PROVEEDOR(-- creado bien -- SIN FOREIGN KEY
	PRO_code int not null auto_increment,
	PRO_nomEmpresa varchar(45) not null,
	PRO_nit varchar(30) default null,
	PRO_nomPersona varchar(45),
	PRO_direccion varchar(45),
	PRO_telefono bigint(15) not null,
	PRO_email varchar(45),
	PRO_concepto varchar(45),

	primary key (PRO_code)
);

create table RUTA(-- creado bien -- SIN FOREIGN KEY
	RUT_code int not null,
	RUT_nombre varchar(30) not null,
	RUT_longAprox int,
	RUT_durAprox int,
	RUT_gananProm int,
	RUT_concepto varchar(45),

	primary key(RUT_code)
);

create table VENDEDOR(-- creado bien
	VEN_idEmple int not null,
	VEN_idRuta int not null,
	VEN_subsidio int default 0,

	primary key (VEN_idEmple),
	foreign key (VEN_idEmple) references EMPLEADO(EMP_code),
	foreign key (VEN_idRuta) references RUTA(RUT_code)
);

create table CLIENTE(-- creado bien
	CLI_code int not null auto_increment,
	CLI_nombre varchar(30) not null,
	CLI_apellido varchar(30),
	CLI_id varchar(17),
	CLI_telefonoCel BIGINT(17),
	CLI_telefonoFij BIGINT(17),
	CLI_direccion varchar(45),
	CLI_idRuta int not null,
	CLI_email varchar(30),
	CLI_concepto varchar(45),

	primary key (CLI_code),
	foreign key (CLI_idRuta) references RUTA(RUT_code)
);

create table PAN_CATEGORIA(-- creado bien -- SIN FOREIGN KEY
	PAN_CAT_nombre varchar(30) not null,
	PAN_CAT_precioCalle int not null,
	primary key (PAN_CAT_nombre)
);

create table VENDEDOR_PRECIO(-- CREADO BIEN
	VEN_PRE_idVend int not null,
	VEN_PRE_idCategPan varchar(30) not null,
	VEN_PRE_precio int not null,

	primary key (VEN_PRE_idVend,VEN_PRE_idCategPan),
	foreign key(VEN_PRE_idVend) references VENDEDOR(VEN_idEmple),
	foreign key(VEN_PRE_idCategPan) references PAN_CATEGORIA(PAN_CAT_nombre)

);

create table PAN(
	PAN_code int not null auto_increment,
	PAN_nombre varchar(30) not null,
	PAN_idCategPan varchar(30) not null,
	PAN_costoProduc int ,

	primary key (PAN_code),
	foreign key (PAN_idCategPan) references PAN_CATEGORIA(PAN_CAT_nombre)
); 

create table UNIDAD_MEDIDA(
	UND_MED_nombre varchar(30) not null,
	UND_MED_valorLibras float not null,
    primary key (UND_MED_nombre)
);


create table MATERIA_PRIMA_CATEGORIA(
	MAT_PRI_CAT_nombre varchar(30) not null,
    primary key (MAT_PRI_CAT_nombre)/* pendiente de agregar mascontenido */ 
);

create table MATERIA_PRIMA(
	MAT_PRI_code int not null auto_increment,
	MAT_PRI_nombre varchar(30) not null,
	MAT_PRI_marca varchar(30),
	MAT_PRI_idUndMedida varchar(30) not null,
	MAT_PRI_presentacion varchar(30) not null,
	MAT_PRI_precioUnd int not null,
	MAT_PRI_idCategMat varchar(30) not null,/* en la unidad menor */
	MAT_PRI_fechaCadu date,

	primary key (MAT_PRI_code),
	foreign key (MAT_PRI_idUndMedida) references UNIDAD_MEDIDA(UND_MED_nombre),
	foreign key (MAT_PRI_idCategMat) references MATERIA_PRIMA_CATEGORIA(MAT_PRI_CAT_nombre)
);


create table PAQUETE(
	PAQ_nombre varchar(30) not null,
	PAQ_idPan int not null,
	PAQ_idCategPan varchar(30) not null,
	PAQ_numPorPaq int not null,
	PAQ_idMateria int not null,
    PAQ_precioCalle int not null,

	primary key (PAQ_nombre),
	foreign key (PAQ_idMateria) references MATERIA_PRIMA(MAT_PRI_code),
	foreign key (PAQ_idPan) references PAN(PAN_code),
	foreign key (PAQ_idCategPan) references PAN_CATEGORIA(PAN_CAT_nombre)
);


create table CLIENTE_ESPECIAL(
	CLI_ESP_idClien int not null,
	CLI_ESP_idPaque varchar(30) not null,
	CLI_ESP_precioFull int not null,
	CLI_ESP_precioMin int not null,
	CLI_ESP_minVol int not null,
	CLI_ESP_porcenVend float not null,
	CLI_ESP_concepto varchar(45) default null,
    

	primary key (CLI_ESP_idClien,CLI_ESP_idPaque),
	foreign key (CLI_ESP_idClien) references CLIENTE(CLI_code),
	foreign key (CLI_ESP_idPaque) references PAQUETE(PAQ_nombre)
);


create table VENTA(
	VENT_factura int not null auto_increment,
	VENT_idVende int not null,
	VENT_fecha date not null,
	VENT_totalPaq int,
	VENT_valorTotal int,
	VENT_pagoVend float,
	VENT_pagoVendSin float,
	VENT_idClienEsp int default null,
	VENT_condMin boolean default true,
	VENT_condSub boolean default true,
	VENT_condPago boolean default true,
	VENT_idRuta int,
	VENT_estado varchar(15) not null,

	primary key (VENT_factura),
	foreign key (VENT_idVende) references VENDEDOR(VEN_idEmple),
	foreign key (VENT_idClienEsp) references CLIENTE_ESPECIAL(CLI_ESP_idClien),
	foreign key (VENT_idRuta) references RUTA(RUT_code)
/* SI EL CLIENTE ES ESPECIAL SE CALCULA LA VENTA RESPECTO A ESE VALOR, SI NO SE CALCULA RESPECTO AL PRECIO QUE SE LE DA AL VENDEDOR */

);
 
 /* LAS TABLAS SE RELACIONAN ENTRE SI PRIMERO AUMENTANDO REGISTROS EN DESPACHO, LUEGO AUMENTANDO REGISTROS EN DEVOLUCIONES Y FINALMENTE EN ITEM VENTA */
create table ITEM_VENTA(
	ITE_VENT_ref int not null,
	ITE_VENT_idPaque varchar(30) not null,
	ITE_VENT_fecha date not null,
	ITE_VENT_idVende int not null,
	ITE_VENT_cantidad int not null,
	ITE_VENT_precio int default 0,
	ITE_VENT_gananVende float default 0,

	primary key (ITE_VENT_ref,ITE_VENT_idPaque),
	foreign key (ITE_VENT_idPaque) references PAQUETE(PAQ_nombre),
	foreign key (ITE_VENT_idVende) references VENDEDOR(VEN_idEmple),
	foreign key (ITE_VENT_ref) references VENTA(VENT_factura)
);

/* NUEVAS TABLAS PARA REFERENCIAR LOS DESPACHOS Y Ls devoluciones */
create table ITEM_DEVOLUCION(
	ITE_DEV_ref int not null,
	ITE_DEV_idPaque varchar(30) not null,
	ITE_DEV_fecha date not null,
	ITE_DEV_idVende int not null,
	ITE_DEV_cantidad int not null,

	primary key (ITE_DEV_ref,ITE_DEV_idPaque,ITE_DEV_idVende),
	foreign key (ITE_DEV_idPaque) references PAQUETE(PAQ_nombre),
	foreign key (ITE_DEV_idVende) references VENDEDOR(VEN_idEmple),
	foreign key (ITE_DEV_ref) references VENTA(VENT_factura)

);

create table ITEM_DESPACHO(
	ITE_DES_ref int not null,
	ITE_DES_idPaque varchar(30) not null,
	ITE_DES_fecha date not null,
	ITE_DES_idVende int not null,
	ITE_DES_cantidad int default 0,

	primary key (ITE_DES_ref,ITE_DES_idPaque,ITE_DES_idVende),
	foreign key (ITE_DES_idPaque) references PAQUETE(PAQ_nombre),
	foreign key (ITE_DES_idVende) references VENDEDOR(VEN_idEmple),
	foreign key (ITE_DES_ref) references VENTA(VENT_factura)

);

/* ****************************************************************** */
create table INVENTARIO_PAN(
	INV_PAN_idPaque varchar(30) not null,
	INV_PAN_cantTotal int default 0,

	primary key(INV_PAN_idPaque),
	foreign key(INV_PAN_idPaque) references PAQUETE(PAQ_nombre)

	);

create table PEDIDO(
	PED_code int not null auto_increment,
	/*PED_idItemPed int not null,*/
	PED_idProve int not null,
	PED_fecha date not null,
	PED_preciototal int,
	PED_estado varchar(15) not null,

	primary key(PED_code),
	/*foreign key (PED_idItemPed) references ITEM_PEDIDO(ITE_PED_ref),*/
	foreign key (PED_idProve) references PROVEEDOR(PRO_code)
);

create table ITEM_PEDIDO(
	ITE_PED_ref int not null,
	ITE_PED_idMatPrima int not null,
	ITE_PED_idProve int not null,
	ITE_PED_fecha date not null,
	ITE_PED_cantidad int not null,
	ITE_PED_precio int,

	primary key(ITE_PED_REF,ITE_PED_idMatPrima,ITE_PED_idProve),
	foreign key (ITE_PED_idMatPrima) references MATERIA_PRIMA(MAT_PRI_code),
	foreign key (ITE_PED_ref) references PEDIDO(PED_code),
	foreign key (ITE_PED_idProve) references PROVEEDOR(PRO_code)

);



/*/* A LA INVERSA DE ATRAS PARA ADELANTE *******************************************************************************************************      */
/* *************************************************************************************************************************************************   */
create table MOJE(
	MOJ_idPaque varchar(30) not null,
	MOJ_cantidad int not null,
	MOJ_fecha date not null,

	primary key(MOJ_idPaque),
	foreign key (MOJ_idPaque) references PAQUETE(PAQ_nombre)
);

create table ITEM_COBRAR(
	ITE_COB_ref int not null,
	ITE_COB_idPaque varchar(30) not null,
	ITE_COB_fecha date not null,
	ITE_COB_cantidad int not null,
	ITE_COB_idVende int not null,

	primary key (ITE_COB_ref,ITE_COB_idPaque,ITE_COB_idVende),
	foreign key (ITE_COB_idPaque) references PAQUETE(PAQ_nombre),
	foreign key (ITE_COB_idVende) references VENDEDOR(VEN_idEmple)

);

create table COBRAR(
	COB_code int not null,
	COB_idItemCob int not null,
	COB_idVende int not null,
	COB_fechaAdq date not null,
	COB_concepto varchar(45),
	COB_valor int not null,
	COB_idCliente int not null,

	primary key (COB_code),
	foreign key (COB_idItemCob) references ITEM_COBRAR(ITE_COB_ref),
	foreign key (COB_idVende) references VENDEDOR(VEN_idEmple),
	foreign key (COB_idcliente) references CLIENTE(CLI_code)

);

-- create table ITEM_GASTO(
	-- ITE_GAS_idGasto int not null,
	-- ITE_GAS_fecha date not null,
	-- ITE_GAS_concepto varchar(60),
	-- ITE_GAS_valor int not null,

	-- foreign key (ITE_GAS_idGasto) references GASTO(ITE_GAS_idGasto)
-- );

 create table GASTO(
	 GAS_code int not null auto_increment,
	 GAS_fecha date not null,
	 GAS_concepto varchar(60) not null,
	 GAS_valor int default 0,

	 primary key (GAS_code)
 );

create table DEUDA(
	DEU_code int not null auto_increment,
	DEU_nomTercero varchar(30) not null,
	DEU_id varchar(30),
	DEU_telefono BIGINT(16),
	DEU_concepto varchar(45) not null,
	DEU_fechaAdq date not null,
	DEU_valor int not null,

	primary key (DEU_code)
);

create table DEUDA_PAGADA(
	DEU_PAG_code int not null,
	DEU_PAG_nomTercero varchar(30) not null,
	DEU_PAG_id varchar(30),
	DEU_PAG_telefono BIGINT(16),
	DEU_PAG_concepto varchar(45) not null,
	DEU_PAG_fechaAdq date not null,
	DEU_PAG_valor int not null,

	primary key (DEU_PAG_code)
);

create table CAJA(
	CAJ_fecha date not null,
	CAJ_ventas int not null,
	CAJ_costos int not null,
	CAJ_gastos int not null,
	CAJ_provLabo int not null,
	CAJ_ingresos int not null,

	primary key (CAJ_fecha)
);

create table BANCO(
	ITE_BAN_code int not null auto_increment,
	ITE_BAN_fecha date not null,
	ITE_BAN_tipo varchar(15) not null,
	ITE_BAN_cantidad int not null,

	primary key (ITE_BAN_code)
);

create table NOMINA(
	NOM_idEmple int not null,
	NOM_idContrato varchar(30) not null,
	NOM_SalarioDEv int not null,/* con los respectivos decuentos */ 
	NOM_fechaIniTraba date not null,
	NOM_fechaIniPeriodo date not null,
	NOM_fechaFinPeriodo date not null,
	NOM_adelantoPeriodo int default 0,

	primary key (NOM_idEmple,NOM_idContrato),
	foreign key (NOM_idEmple) references EMPLEADO(EMP_code),
	foreign key (NOM_idContrato) references CONTRATO(CON_nombre)

);

create table ITEM_CONTRATO(
	ITE_CON_ref int not null,
	ITE_CON_concepto varchar(45) not null,
	ITE_CON_tipo varchar(15) not null,/* clasificacion de tipo porcentual o fijo */
	ITE_CON_valor int not null,

	primary key (ITE_CON_ref,ITE_CON_concepto)
);

create table CONTRATO(
	CON_nombre varchar(30) not null,
	CON_idItemCon int not null,
	CON_concepto varchar(45),

	primary key (CON_nombre),
	foreign key (CON_idItemCon) references ITEM_CONTRATO(ITE_CON_ref)

);

create table ITEM_RECETA(
	ITE_REC_idNombre varchar(30) not null,
	ITE_REC_idMatPrima int not null,
	ITE_REC_cantidad int not null,
	ITE_REC_precio int not null,/* se calcula segun la cantidad usada y el precio de esta materia prima */

	primary key (ITE_REC_idNombre,ITE_REC_idMatPrima),
	foreign key (ITE_REC_idMatPrima) references MATERIA_PRIMA(MAT_PRI_code),
	foreign key (ITE_REC_idNombre) references RECETA(REC_nombre)
);

create table RECETA(/* programar las recetas de las cuales se tiene dato y las que no aproximarlas a precio de regla de 3 */
	REC_nombre varchar(30) not null,
	REC_durMedia int,
	REC_precioTot int not null,

	primary key (REC_nombre)
);

create table PRODUCCION(/* Cuando los paquetes de pan son contados para subir al inventario */
	PROD_fecha date not null,
	PROD_idCreacion int not null,
	PROD_idPaque varchar(30) not null,
	PROD_cantidad int not null,

	primary key (PROD_fecha,PROD_idCreacion),
	foreign key (PROD_idCreacion) references CREACION(CRE_code)

);

create table CREACION(/* cuando se separa la materia prima y se comienza a trabajar */
	CRE_code int not null auto_increment,
	CRE_idRece varchar(30) not null,
	CRE_fecha date not null,
	CRE_estado varchar(45),

	primary key(CRE_code),
	foreign key(CRE_idRece) references RECETA(REC_nombre)
/* cuando se crea esta orden de creacion se debe crear una alarma en algun lado que permita concluir esta orden junto con el conteo de los paquetes */
);

create table INVENTARIO_MATERIA_PRIMA(
	INV_MAT_PRI_idMatPrima int not null,
	INV_MAT_PRI_cantidad int not null,

	primary key (INV_MAT_PRI_idMatPrima),
	foreign key (INV_MAT_PRI_idMatPrima) references MATERIA_PRIMA(MAT_PRI_code)
);

-- abuevas maneras para probar
 create table REGISTRO_DIA(
 	-- venta,produccion,moje
 	REG_DIA_fecha date not null,
 	REG_DIA_tipo varchar(15) not null,
 	REG_DIA_idPaque varchar(30) not null,
 	REG_DIA_cantidad int not null,

 	primary key (REG_DIA_fecha,REG_DIA_tipo,REG_DIA_idPaque),
 	foreign key (REG_DIA_idPaque) references PAQUETE(PAQ_nombre)
 	);

create table INGRESO(
	 ING_code int not null auto_increment,
	 ING_fecha date not null,
	 ING_concepto varchar(60) not null,
	 ING_valor int default 0,

	 primary key (ING_code)
 );


/* *************************************************************************************************************************************************   */
/* *************************************************************************************************************************************************   */ 

	-- TABLAS AUXILIARES &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
create table BUFFER_REG_DIA(
	BUF_REG_DIA_idPaque varchar(30),
	BUF_REG_DIA_cantidad int,
	foreign key (BUF_REG_DIA_idPaque) references PAQUETE(PAQ_nombre)
);

create table USUARIO(
	USU_login varchar(30) not null,
	USU_pass varchar(30) not null,
	USU_idEmple int,
	USU_permiso int not null,

	primary key (USU_login,USU_pass)
);













 









