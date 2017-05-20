/* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& PRODUCCION &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& */
/* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& */
/* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& */

delimiter &&/* TIPO PARA VER SI SE DECUENTA O NO DEL INVENTARIO LA INFORMACION */
create function CrearPan(tipo int,rece varchar(30),fecha date) returns varchar(15)
	begin 
		START TRANSACTION;
			insert into CREACIONES values(null,rece,fecha,'iniciado');
				declare materia int;
				declare cantidad int;

				set item_ref = select REC_idItemRec from RECETA where REC_nombre = rece;

				update INVENTARIO_MATERIA_PRIMA as mat set INV_MAT_PRI_cantidad = INV_MAT_PRI_cantidad 
					- ite.ITE_REC_cantidad from ITEM_RECETA ite where ite.ITE_REC_idMatPrima = mat.INV_MAT_PRI_idMatPri
						and ite.ITE_REC_ref = item_ref;
				declare salida int;
				set salida = verifiExisMatPrima(item_ref);

				if salida = 'bien' then
						commit;
					else
						rollback;
				end if;	

		return salida;
	end &&
delimiter ;


delimiter &&
create procedure ProducirPan(fecha date,idCrea int,idPaq varchar(30),cant int)
	begin
		insert into PRODUCCION values (null,fecha,idCrea,idPaq,cant);
			update CREACION set CRE_estado = 'finalizado' where CRE_code = idCrea;
				/*aqui va la parte de aumentar el inventario de pan */
				update INVENTARIO_PAN set INV_PAN_cantTotal = INV_PAN_cantTotal + cant;
	end &&
delimiter ;


	/* auxiliares a produccion*/
	delimiter &&
		create function verifiExisMatPrima (int ref) returns varchar(15)
			begin 
			
				declare continue handler for not found set @hecho = true;
				declare cursor_cliente CURSOR for select INV_MAT_PRI_idMatPri,INV_MAT_PRI_cantidad;
					from INVENTARIO_MATERIA_PRIMA;
				declare matPrim int;
				declare cant int;	
				open cursor_cliente;

					loop1: LOOP
						 fetch cursor_cliente into matPrim,cant;
						 	if cant <= 0 then 
						 		declare salida;
						 		set salida = select MAT_PRI_nombre from MATERIA_PRIMA 
						 			where MAT_PRI_code = matPrim;
						 		leave loop1;
						 		return salida;
						 		end if;
						 	if @hecho then 
						 		leave loop1;
						 	end if;	
					end loop1;
					close cursor_cliente;
				return 'bien';
		end &&
	delimiter ;
	/* *********************** */


/* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& PEDIDO MATERIA PRIMA &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& */
/* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& */
/* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& */


delimiter &&
create function iniPedirMateria(prove int,fecha date) returns int
	begin
		insert into PEDIDO values (null,prove,fecha,'iniciado');
			return LAST_INSERT_ID();
	end &&
delimiter ;

delimiter &&
create procedure itemPedirMateria(ref int,materia int,fecha date,cantidad int)
	begin
		declare prove int;
		declare precio int;
		set prove = select PED_idProve from PEDIDO where PED_CODE = ref;
		set precio = ((select MAT_PRI_precioUnd from MATERIA_PRIMA where MAT_PRI_code = materia ) * (cantidad));
		insert into ITEM_PEDIDO values (ref,materia,prove,fecha,cantidad,precio);
	end &&
delimiter ;

delimiter &&/* crear un limpiador por si el sistema cae mientras se realiza la insercion */
	create function finPedirMateria(code int,estado boolean) return varchar(7)
		begin
			if estado then 
				update INVENTARIO_MATERIA_PRIMA set INV_MAT_PRI_cantidad 
					= INV_MAT_PRI_cantidad + ite.ITE_PED_cantidad from ITEM_PEDIDO ite
						where ite.ITE_PED_ref = code and 
							ite.ITE_PED_idMatPrima = INV_MAT_PRI_idMatPri;
				update PEDIDO set PED_estado = 'finalizado'	where PED_code = code;
				update PEDIDO set PED_precioTotal = SUM(ite.ITE_PED_precio)
					from ITEM_PEDIDO ite where ite.ITE_PED_ref = code;
						else
							delete from ITEM_PEDIDO where ITE_PED_ref = code;
							delete from PEDIDO where PED_code = code;
			end if;
		end &&
delimiter ;
/* falta crear un triguer o funcion que al inicio del programa borre los item pedido de las partes en las que no se finalizo correctamente el pedido */


/* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& VENTAS &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& */
/* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& */
/* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& */

delimiter &&
create function iniVender(vende int,fecha date,client int,ruta int) returns int
	begin
		insert into VENTA values (null,vende,fecha,0,0,0,client,ruta,'iniciado');
			return LAST_INSERT_ID();
	end &&
delimiter ;


delimiter&&
	create function itemDespachar(fact int,tipoPaq varchar(30),fecha date,cantidad int) returns varchar(30)
		begin
			start TRANSACTION
				declare vende int;
				set vende = select VENT_idVende from VENTA where VENT_factura = fact;

				insert into ITEM_DESPACHO values (fact,tipoPaq,fecha,vende,cantidad);
					update INVENTARIO_PAN set INV_PAN_cantTotal = INV_PAN_cantTotal - cantidad;
						declare salida varchar(30);
						 set salida = select verifiExisPan(tipoPaq);

						 if salida = 'bien' then
						 	commit;
						 	 else
						 	   rollback;
						 	   -- cambiar para verificar cuando se tengan varios despachos de una sola venta
						 end if;
					return salida;
	end &&	
delimiter ;

delimiter&&
	create function itemDevolucion(fact int,tipoPaq varchar(30),fecha date,cantidad int) returns varchar(30)
		begin
			start TRANSACTION
				declare salida varchar(30);
				declare vende int;
				set salida = verifiExisDespa(fac,tipoPaq,cantidad);
				if salida = 'bien' then
					set vende = select VENT_idVende from VENTA where VENT_fact = fact;
					insert into ITEM_DEVOLUCION values (fact,tipoPaq,fecha,vende,cantidad);

					commit;
						else
							/* revisar esta funcion */
							rollback;

		end if;
				return salida;
	end &&	
delimiter ;

delimiter &&
		create function verifiExisPan (varchar(30) nombre) returns varchar(30)
			begin 
				declare aux int;
				set aux = select INV_PAN_cantTotal from INVENTARIO_PAN inv right join 
					PAQUETE paq on inv.INV_PAN_idPaque = paq.PAQ_nombre;
				if aux > 0 then
						return 'bien';
						else
						return nombre;
					end if; 
		end &&
delimiter ;

delimiter &&
		create function verifiExisDespa (ref int,nombre varchar(30),cantidad int) returns varchar(30)
			begin 
				declare salida varchar(30);
				declare compa int;

				set compa = select ITE_DES_cantidad from ITEM_DESPACHO 
					where ITE_DES_idPaque = nombre and ITE_DES_ref = ref;

					if cantidad <= compa then
						return 'bien';
						else
						return nombre;
						end if;

		end &&
delimiter ;

delimiter &&
	create funcion finVenta(ref int,estado boolean,cliente_esp ) returns varchar(7)
		begin
			start transaction 
				if estado then
					/* seleccion de cursores gracias a que se busca actualizar 
						pags punto por punto */ 
						declare done boolean default false;
						declare continue handler for not found set done = true;
						declare cursor_despacho cursor for select ITE_DES_idPaque,
							ITE_DES_fecha,ITE_DES_idVende,ITE_DES,ITE_DES_cantidad
						from ITEM_DESPACHO where ITE_DES_ref = ref;

						declare aux_desp_paq varchar(30);
						declare aux_desp_cant int;
						declare aux_devo int default 0;
						declare aux_desp_fecha date;
						declare aux_desp_vend int;



							open cursor_despacho;
								loop1 : loop
									fetch cursor_despacho into aux_desp_paq,aux_desp_fecha,
										aux_desp_vend,aux_desp_cant;

									set aux_devo = select ITE_DEV_cantidad from ITEM_DEVOLUCION
										where ITE_DEV_ref = ref and ITE_DEV_idPaque = aux_desp_paq;
									
									if aux_devo is NULL then
										insert into ITEM_VENTA values(ref,aux_desp_paq,aux_desp_fecha,
												aux_desp_vend,aux_desp_cant);
										else
											insert into ITEM_VENTA values(ref,aux_desp_paq,aux_desp_fecha,
												aux_desp_vend,aux_desp_cant - aux_devo);
									end if;

/* terminar esta funcion !!! */


									if done then
										leave loop1;
									end if;
								end loop1;

								update VENTA set VENT_totalPaq 
								/* aqui se actualiza la parte de la venta de la operacion */
								declare tipo_client int;
								declare exists_client int;

								set tipo_client = select VENT_idClient from VENTA 
									where VENT_factura = ref; 
								/* parte que permitira calcular el porcentaje del vendedor dependiendo
									de si es un cliente especial o si simplemente es cualquiera */
								if tipo_client = -1 then
									/* aqui es cuando el cliente es el cualquiera sin definir*/
									update VENTA set VENT_pagoVen
								end if;
						/* no olvidar colocar commit y rollback !!! */
						close cursor_despacho;
					else
							/* colocar aca lo que va en el caso de que se cancele la operacion*/
			end if;

	end &&
delimiter ;



delimiter &&
	create procedure calcGananVendedor(ref int,actSubsi boolean)
		begin
			start transaction
				declare aux_clien int;
				declare is_esp int default NULL;
				declare valor_venta int default 0;
				declare ganancia int default 0;

				set aux_clien = select VENT_idClienEsp from VENTA
					where VENT_factura = ref;
				set is_esp = select SUM(CLI_ESP_precioMin) from CLIENTE_ESPECIAL
					where CLI_ESP_idClien = ref;
				set valor_venta = select VENT_valorTotal from VENTA 
					where VENT_factura = ref;
						

					if is_esp is NULL then
					--EL CLIENTE NO ES ESPECIAL, SE COBRA SEGUN PRECIOS DE VENDEDOR

						else
					-- EL CLIENTE ES ESPECIAL, SE COBRA SEGUN EL PORCENTAJE ASIGNADO
					declare porcen_vend FLOAT;
					set porcen_vend = select CLI_ESP_porcenVend from CLIENTE_ESPECIAL
						where CLI_ESP_idClien = aux_clien;
					set ganancia = valor_venta * porcen_vend;
					end if;	
		end &&
delimiter ;

	create function mirarGananciaVend(ref int) returns int
		begin-- se debe verificar antes que ya se cumplio la venta
			start transaction
				declare aux_clien int;
				declare is_esp int default NULL;
				declare ganancia Float default 0;
				set aux_clien = select VENT_idClienEsp from VENTA
					where VENT_factura = ref;
				set is_esp = select SUM(CLI_ESP_precioMin) from CLIENTE_ESPECIAL
					where CLI_ESP_idClien = ref;

					if is_esp is NULL then
					-- cliente no es especial
					set ganancia = SUM( (VEN_PRE_precio * ITE_VEN_cantidad)) from ITEM_VENTA join VENDEDOR_PRECIO join PAN join PAQUETE
						on ITE_VENT_idPaque = PAQ_nombre and PAQ_idPan = PAN_code and PAN_idCategPan = VEN_PRE_idCategPan where ITE_VENT_ref = ref; 

						else
							declare aux_vent Float;
							set aux_vent = select VENT_valorTotal from VENTA
								where VENT_factura = ref;
							-- el cliente es especial


					end if;

			commit;

		end &&

delimiter &&


delimiter ;



delimiter &&
	create procedure calcTotalVenta(ref int,actMinVol boolean)
		begin
			start transaction
				declare aux_clien int;
				declare is_esp int default NULL;
				set aux_clien = select VENT_idClienEsp from VENTA
					where VENT_factura = ref;
				set is_esp = select SUM(CLI_ESP_precioMin) from CLIENTE_ESPECIAL
					where CLI_ESP_idClien = aux_clien;

					if is_esp is NULL then
					/* seccion para ver el comportamiento de la venta si el cliente
						es cualquiera no registrado y se le vende a precio calle normal */
						-- calculo del precio total de la venta
						declare aux_total_vent int;
						set aux_total_vent = select SUM(PAQ_precioCalle) from
							ITEM_VENTA inner join PAQUETE where ITE_VEN_ref = ref;
						update VENTA set VENT_valorTotal = aux_total_vent 
								where VENT_factura = ref;

						else
							-- el cliente registrado si es especial
								declare dinero_clien int default 0;

								declare done boolean default false;
								declare continue handler for not found set done = true;
								declare cursor_categ cursor for select ITE_VENT_idPaque,
									ITE_VENT_cantidad from ITEM_VENTA where ITE_VENT_ref = ref;
									declare cur_paq varchar(30);
									declare cur_cant int;
									declare min_vol_clien int;
									declare valor_paq_actual int;


									open cursor_categ;
										loop1:loop

											fetch cursor_categ into cur_paq,cur_cant;
											set min_vol_clien = select CLI_ESP_minVol from CLIENTE_ESPECIAL
												where CLI_ESP_idClien = aux_clien and CLI_ESP_idPaque = cur_paq;
											-- condiciones para diferenciar si se usa el maximo, minimo o precio normal 
											-- de cada paquete
											if actMinVol then
													-- es importante considerar el minimo volumen
												if cur_cant >= min_vol_clien then
													-- la venta supera el volumen minimo
													set valor_paq_actual = select CLI_ESP_precioMin from CLIENTE_ESPECIAL
														where CLI_ESP_idClien = aux_clien and CLI_ESP_idPaque=cur_paq;
													set dinero_clien = dinero_clien + (valor_paq_actual * cur_cant);
													else
														set valor_paq_actual = select CLI_ESP_precioFull from CLIENTE_ESPECIAL
														where CLI_ESP_idClien = aux_clien and CLI_ESP_idPaque=cur_paq;
														set dinero_clien = dinero_clien + (valor_paq_actual * cur_cant);
														-- la venta no supero el volumen minimo
												end if;
												else
													set valor_paq_actual = select CLI_ESP_precioMin from CLIENTE_ESPECIAL
														where CLI_ESP_idClien = aux_clien and CLI_ESP_idPaque=cur_paq;
													set dinero_clien = dinero_clien + (valor_paq_actual * cur_cant);
											end if;


											if done then
												leave loop1;
												
											end if;
										end loop1;
									close cursor_categ;
									-- actualiza la tabla de ventas realmente
						update VENTAS set VENT_valorTotal = dinero_clien where VENT_factura = ref;
					end if;	
					commit;
		end &&
delimiter ;

delimiter ;