-- &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& PRODUCCION &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& */
-- &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& */
-- &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& */


drop function verifiExisMatPrima;
delimiter &&
		create function verifiExisMatPrima (ref int) returns varchar(15) -- ya &&
			begin 
			
				declare matPrim int;
				declare cant int;	
                declare salida varchar(15);
                
                declare cursor_cliente CURSOR for select INV_MAT_PRI_idMatPri,INV_MAT_PRI_cantidad from INVENTARIO_MATERIA_PRIMA;
				declare continue handler for not found set @hecho = true;
                
				open cursor_cliente;

					loop1: LOOP
                    
						 fetch cursor_cliente into matPrim,cant;
                         
							if cant <= 0 then 
								set salida = (select MAT_PRI_nombre from MATERIA_PRIMA where MAT_PRI_code = matPrim);
								leave loop1;
								return salida;
							end if;
                                
							if @hecho then 
								leave loop1;
							end if;	
                            
					end loop loop1;
					close cursor_cliente;
				return 'bien';
		end &&
	delimiter ;

DROP PROCEDURE CrearPan;
delimiter &&
create procedure CrearPan(rece varchar(30),fecha date,inout ValorOut int) -- ya &&
	begin 
			declare materia int;
			declare cantidad int;
            declare item_ref int;
            declare salida varchar(15);
            
		 START TRANSACTION;
        
			insert into CREACION values(null,rece,fecha,'iniciado');
			
				set item_ref = (select REC_idItemRec from RECETA where REC_nombre = rece);
				update INVENTARIO_MATERIA_PRIMA right join ITEM_RECETA on ITE_REC_idMatPrima = INV_MAT_PRI_idMatPrima
					 set INV_MAT_PRI_cantidad = (INV_MAT_PRI_cantidad -ITE_REC_cantidad ) where ITE_REC_idNombre = rece;
				
				set salida = verifiExisMatPrima(item_ref);

				if salida = 'bien' then
						set ValorOut = LAST_INSERT_ID();
                        commit;
					else
						set ValorOut = (-1);
                        rollback;
				end if;	
	end &&
delimiter ;

drop procedure ProducirPan;
delimiter &&
create procedure ProducirPan(fecha date,idCrea int,idPaq varchar(30),cant int)-- ya &&
	begin
		start transaction;
		insert into PRODUCCION values (null,fecha,idCrea,idPaq,cant);
			update CREACION set CRE_estado = 'finalizado' where CRE_code = idCrea;
				call actualizarInvCreacion(fecha);
			commit;	
	end &&
delimiter ;


	-- auxiliares a produccion
	drop procedure actualizarInvCreacion;
delimiter &&
		create procedure actualizarInvCreacion(fecha date)-- YA &&
			begin
					declare aux_paque varchar(30);
					declare aux_suma int;
					declare done boolean default false;
                    declare cursor1 cursor for select * from BUFFER_REG_DIA;
					declare continue handler for not found set done = true;
	
				start transaction;
					
					insert into BUFFER_REG_DIA select PROD_idPaque,sum(PROD_cantidad) from PRODUCCION
						 where PROD_fecha = fecha  group by PROD_idPaque;
				
					 open cursor1;
					 loop1 : LOOP
						 fetch cursor1 into aux_paque,aux_suma;
						 call modifiRegisDiario(fecha,'produccion',aux_paque,aux_suma);
					 if done then
						leave loop1;
					end if;
			  end LOOP loop1;
		  close cursor1;
		  delete from BUFFER_REG_DIA;
			commit;
		end &&
	delimiter ;

-- MOJE DE PAN &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
-- &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
-- &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
drop procedure MojePan;
delimiter &&
	create procedure MojePan(fecha date,paque varchar(30),cantidad int)-- ya &&
		begin
			declare aux_cantidad int;
			declare aux_total int;
			start transaction;
				set aux_cantidad = (select REG_DIA_CANTIDAD from REGISTRO_DIA where 
					REG_DIA_fecha = fecha and REG_DIA_tipo = 'moje' and REG_DIA_idPaque = paque);
				if aux_cantidad is NULL then
					CALL modifiRegisDiario(fecha,'moje',paque,cantidad);
					else
						set aux_total = aux_cantidad + cantidad;
							CALL modifiRegisDiario(fecha,'moje',paque,aux_total);
				end if;
			commit;
		end &&
delimiter ;



/* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& PEDIDO MATERIA PRIMA &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& */
/* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& */
/* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& */

drop function iniPedirMateria;
delimiter &&
create function iniPedirMateria(prove int,fecha date) returns int -- &&ya
	begin
		insert into PEDIDO values (null,prove,fecha,'iniciado');
			return LAST_INSERT_ID();
	end &&
delimiter ;

drop procedure itemPedirMateria;
delimiter &&
create procedure itemPedirMateria(ref int,materia int,fecha date,cantidad int)-- ya &&
	begin
		declare prove int;
		declare precio int;
        start transaction;
			set prove = (select PED_idProve from PEDIDO where PED_CODE = ref);
			set precio = ((select MAT_PRI_precioUnd from MATERIA_PRIMA where MAT_PRI_code = materia ) * (cantidad));
			insert into ITEM_PEDIDO values (ref,materia,prove,fecha,cantidad,precio);
        commit;
	end &&
delimiter ;

drop procedure finPedirMateria;
delimiter &&
	create procedure finPedirMateria(codi int,estado boolean,efectivo boolean,adeudar boolean,inout valorOut varchar(7))-- YA&&
		proc_label:begin
			declare aux_pago int;
			declare aux_valor int;
			declare aux_fecha date;
			start transaction;
            
			if estado then 
				

				set aux_fecha = (select PED_fecha from PEDIDO where PED_code = codi);
                update PEDIDO set PED_precioTotal = (select SUM(ite.ITE_PED_precio) from ITEM_PEDIDO ite where ite.ITE_PED_ref = codi);
				set aux_valor = (select PED_precioTotal FROM PEDIDO where PED_code = codi);

				if efectivo then
					set aux_pago = dineroCaja(aux_fecha);
						else
					set aux_pago = dineroBanco();
				end if;

				if aux_pago < aux_valor then
					set valorOut = 'falta';
						leave proc_label;
				end if;


                update INVENTARIO_MATERIA_PRIMA right join ITEM_PEDIDO on ITE_PED_idMatPrima = INV_MAT_PRI_idMatPrima
					set INV_MAT_PRI_cantidad = (INV_MAT_PRI_cantidad + ite.ITE_PED_cantidad) where ite.ITE_PED_ref = codi 
						and ite.ITE_PED_idMatPrima = INV_MAT_PRI_idMatPri;
                        
				update PEDIDO set PED_estado = ('finalizado') where PED_code = codi;
				
				if adeudar then
						call deudaMateriaPrima(codi,@salida);
						else
							if efectivo then
								call hacerGastoCaja(aux_fecha,'materia',aux_valor,@salida);
									else
                                    call hacerGastoBanco(aux_fecha,'materia',aux_valor,@salida);
                            end if;
                end if;
                
					set	valorOut = 'bien';
						else
							delete from ITEM_PEDIDO where ITE_PED_ref = code;
							delete from PEDIDO where PED_code = code;
					set	valorOut = 'mal';
			end if;
		end &&
delimiter ;


/* falta crear un triguer o funcion que al inicio del programa borre los item pedido de las partes en las que no se finalizo correctamente el pedido */
-- falta verificar el movimiento de caja de da la compra de mercancia 

/* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& VENTAS &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& */
/* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& */
/* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& */

drop function iniVender;
delimiter &&
create function iniVender(vende int,fecha date,cliente int,cond boolean,subsi boolean,ruta int) returns int-- YA &&
	begin
		insert into VENTA values (null,vende,fecha,0,0,0,cliente,cond,subsi,ruta,'iniciado');
			return LAST_INSERT_ID();
	end &&
delimiter ;

drop procedure itemDespachar;
delimiter &&
	create procedure itemDespachar(fact int,tipoPaq varchar(30),fecha date,cantidad int,inout valorOut varchar(7))-- ya&&
		begin
			declare vende int;
			declare cond boolean;
			declare salida varchar(30);
			declare exisPan varchar(7);
			
            start TRANSACTION;
				

				set cond = (select VENT_condMin from VENTA where VENT_factura = fact);
				set vende = (select VENT_idVende from VENTA where VENT_factura = fact);
				set salida = verifiExisDespa(fact,tipoPaq,-1);
				set exisPan = verifiExisPan(tipoPaq,cantidad);

				if exisPan = 'bien' then

						if salida = 'bien' then
							update ITEM_DESPACHO set ITE_DES_cantidad = ITE_DES_cantidad + cantidad; 
								else 
									insert into ITEM_DESPACHO values (fact,tipoPaq,fecha,vende,cantidad);
						end if;
						-- call actualizarVenta(fact,tipoPaq);
						set valorOut = 'bien';
					else
						set valorOut = 'falta';
				end if;
			commit;	
	end &&	
delimiter ;


drop procedure itemDevolucion;
delimiter &&
	create procedure itemDevolucion(fact int,tipoPaq varchar(30),fecha date,cantidad int,inout valorOut varchar(7))-- YA
		begin
				declare exisDesp varchar(30);
				declare vende int;
				declare existe varchar(30);
				declare cond boolean;
                
			start TRANSACTION;
				

				set cond = (select VENT_condMin from VENTA where VENT_factura = fact);
                set existe = (select ITE_DEV_cantidad from ITEM_DEVOLUCION where ITE_DEV_ref = fact and ITE_DEV_idPaque = tipoPaq);
				set exisDesp = verifiExisDespa(fac,tipoPaq,cantidad);
				
				if exisDesp = 'bien' then

					set vende = (select VENT_idVende from VENTA where VENT_fact = fact);

					if existe is NULL then
							insert into ITEM_DEVOLUCION values (fact,tipoPaq,fecha,vende,cantidad);
						else
							update ITEM_DEVOLUCION set ITE_DEV_cantidad = ITE_DEV_cantidad + cantidad
									where ITE_DEV_ref = fact and ITE_DEV_idPaque = tipoPaq;
					end if;

						-- call actualizarVenta(ref,tipoPaq);
						set valorOut = 'bien';
					commit;
						else
						set valorOut = 'sobra';
							rollback;
		end if;
	end &&	
delimiter ;

drop function verifiExisPan;
delimiter &&
		create function verifiExisPan (nombre varchar(30),cantidad int) returns varchar(7)-- YA &&
			begin 
				declare aux int;
				set aux = (select INV_PAN_cantTotal from INVENTARIO_PAN inv right join 
					PAQUETE paq on inv.INV_PAN_idPaque = paq.PAQ_nombre where paq.PAQ_nombre = nombre);
				if aux >= cantidad then
					return 'bien';
					else
					return 'mal';
				end if;
					
		end &&
delimiter ;

drop function verifiExisDespa;
delimiter &&
		create function verifiExisDespa (ref int,nombre varchar(30),cantidad int) returns varchar(30)-- YA &&
			begin 
				declare salida varchar(30);
				declare compa int;

				set compa = (select ITE_DES_cantidad from ITEM_DESPACHO 
					where ITE_DES_idPaque = nombre and ITE_DES_ref = ref);
					
					if compa is null then
						return 'mal';-- el caso de que se ingrese un valor no valido 
					end if;

					if cantidad <= compa then
						return 'bien';
						else
						return nombre;
						end if;
		end &&
delimiter ;


drop function precioSobrePaqVend;
delimiter &&
	create function precioSobrePaqVend(idVend int,paq varchar(30)) returns Float-- ya &&
		begin 
			declare aux Float;
			set aux = (select VEN_PRE_precio from VENDEDOR_PRECIO join PAN_CATEGORIA join PAQUETE
					on VEN_PRE_idVend = idVend and PAN_CAT_nombre = PAQ_idCategPan where PAQ_nombre = paq);
			return aux;
		end &&
delimiter ;



drop function isEspecial;-- funcion especial para el trigger
delimiter &&
	create function isEspecial(cli_code int) returns boolean-- Ya &&
		begin
			declare aux_salida int;
            
            if cli_code is null then
				return false;
            end if;
            
            set aux_salida = (select CLI_precioFull from CLIENTE_ESPECIAL where CLI_ESP_idClien = cli_code);
            if aux_salida is null then
				return false;
					else
						return true;
            end if;
        end &&
delimiter ;

drop function superaMinimo;
delimiter &&
	create function superaMinimo(ref int,paque varchar(30),cantidad int) returns boolean-- YA &&
	begin
		declare aux_min int;
        declare aux_cliente int;
        declare aux_paque varchar(30);
        
        set aux_cliente = (select VENT_idClienEsp from VENTA where VENT_factura = ref);
        set aux_min = (select CLI_ESP_minVol from CLIENTE_ESPECIAL where CLI_ESP_idClien = aux_cliente and CLI_ESP_idPaque = paque);
        if cantidad < aux_min then
			return false;
				else
					return true;
        end if;
    end &&
delimiter ;

drop procedure actualizarVenta;
delimiter &&
	create procedure actualizarVenta(ref int)-- YA &&
		begin
			start transaction;
			update VENTA join ITEM_VENTA on ITE_VENT_ref = VENT_factura set VENT_valorTotal = sum(ITE_VENT_precio)
				where VENT_factura = ref;
            update VENTA join ITEM_VENTA on ITE_VENT_ref = VENT_factura set VENT_pagoVend = sum(ITE_VENT_gananVende)
				where VENT_factura = ref;
			update VENTA join ITEM_VENTA on ITE_VENT_ref = VENT_factura set VENT_totalPaq = sum(ITE_VENT_cantidad)
				where VENT_factura = ref;
			commit;
        end &&
delimiter ;

drop procedure pagarVendedor;
delimiter &&
	create procedure pagarVendedor(factura int)-- YA&&
    begin
		
		declare aux_valor int;
        declare aux_subsi boolean;
        declare aux_pago float;
        declare aux_fecha date;
        declare salida float;
        
        start transaction;
        
        set aux_valor = (select VEN_subsidio from VENDEDOR join VENTA ON vent_idVende = VEN_idEmple where VENT_factura = factura);
        set aux_subsi = (select VENT_condSub from VENTA where VENT_factura = factura);
        set aux_pago = (select VENT_pagoVend from VENTA where VENT_factura = factura);
        set aux_fecha = (select VENT_fecha from VENTA where VENT_factura = factura);
        
		if aux_subsi then
			if aux_pago < aux_valor then
				set salida = aux_valor;	
                    else
                set salida = aux_pago;    
            end if;
				else
					set salida = aux_pago;
        end if;
        update VENTA set VENT_pagoVendSin = aux_pago where VENT_factura = factura;
        update VENTA set VENT_pagoVend = salida where VENT_factura = factura;
        -- movimiento de caja para registrar el gasto del pago
        insert into GASTO values (null,aux_fecha,'vendedor',salida);
        commit;
    end &&
delimiter ;

delimiter &&
	create procedure actualizarRegistrosDiarios()
		begin
			
        end &&
delimiter ;


drop procedure finVenta;
delimiter &&
	create procedure finVenta(ref int,estado boolean)-- YA &&
		begin
			declare aux_fecha date;
			start transaction;
				if estado then
					set aux_fecha = (select VENT_FECHA from VENTA where VENT_factura = ref);
                    call pagarVendedor(ref);
					update VENTA set VENT_estado = 'finalizado';
							else
								call elimRegisDiarioVenta(ref);
								delete from ITEM_VENTA where ITE_VENT_ref = ref;
								delete from ITEM_DEVOLUCION where ITE_DEV_ref = ref;
								delete from ITEM_DESPACHO where ITE_DES_ref = ref;	
								delete from VENTA where VENT_factura = ref;
				end if;
                 call actualizarCaja(aux_fecha);   
                 call actualizarVentasTotalesDia(aux_fecha);
			commit;
		end &&
delimiter ;

/*delimiter &&
	create procedure elimRegisDiarioVenta(ref int)
		begin-- funcion para eliminar del registro ese tipo de venta
			declare aux_cantidad int;
			set aux_cantidad = (select ITE_VENR)
			update REGISTRO_DIARIO set REG_DIA_cantidad = REG_DIA_cantidad - ITE_VENT_cantidad from
				REGISTRO_DIA left join ITEM_VENTA on REG_DIA_idPaque = ITE_VENT_idPaque where 
					ITE_VENT_ref = ref;
		end &&
delimiter ;*/

drop procedure actualizarVentasTotalesDia;
delimiter &&
	create procedure actualizarVentasTotalesDia(fecha date)-- YA &&
		begin
			declare aux_paque varchar(30);
			declare aux_suma int;
			declare done boolean default false;
			declare cursor1 cursor for select * from BUFFER_REG_DIA;
			declare continue handler for not found set done = true;
			start transaction;

					insert into BUFFER_REG_DIA select ITE_VENT_idPaque,sum(ITE_VENT_cantidad) from ITEM_VENTA
						  where ITE_VENT_FECHA = fecha group by ITE_VENT_idPaque;

					 open cursor1;
					 loop1 : LOOP
						 fetch cursor1 into aux_paque,aux_suma;
						 call modifiRegisDiario(fecha,'venta',aux_paque,aux_suma);
					 if done then
						leave loop1;
					end if;
			  end LOOP loop1;
		  close cursor1;
			delete from BUFFER_REG_DIA;
			commit;
            
		end &&
delimiter ;


-- MANEJO DE LOS REGISTROS DIARIOS DE OPERACION &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
-- &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
-- &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

drop procedure modifiRegisDiario;
delimiter &&
	create procedure modifiRegisDiario(fecha date,tipo varchar(15),paq varchar(30),cantidad int) -- YA &&&
		begin
			declare exis varchar(7);
			start transaction;
				set exis = exisRegisDiario(fecha,tipo,paq);
				if exis = 'bien' then
					update REGISTRO_DIA set REG_DIA_cantidad = caqntidad where
						REG_DIA_fecha = fecha and REF_DIA_TIPO = tipo and REG_DIA_idPaque = paq;
					else
						insert into REGISTRO_DIA values (fecha,tipo,paq,cantidad);
				end if;
			commit;
		end &&
delimiter ;


drop function exisRegisDiario;
delimiter &&
	create function exisRegisDiario(fecha date,tipo varchar(15),paq varchar(30)) returns varchar(7)-- YA &&
		begin
			declare aux int;
			set aux = (select REG_DIA_cantidad from REGISTRO_DIA where REG_DIA_fecha = fecha and
					REG_DIA_tipo = tipo and REG_DIA_idPaque = paq);
			if aux is NULL then
				return 'mal';
				else
					return 'bien';
			end if;
		end &&
delimiter ;

drop procedure actualizarInventario;
delimiter &&
	create procedure actualizarInventario()-- YA &&
		begin
			declare paquete varchar(30);
			declare cantidad int;
			declare aux_venta int;
			declare aux_producido int;
			declare aux_moje int;

			declare done boolean default false;
			declare cursor1 cursor for select INV_PAN_idPaque,INV_PAN_cantTotal from INVENTARIO_PAN;
			declare continue handler for not found set done = true;
            
			start transaction;
            
					 open cursor1;
					 loop1 : LOOP
						 fetch cursor1 into paquete,cantidad;
						 set aux_venta = (select SUM(REG_DIA_CANTIDAD) from REGISTRO_DIA where REG_DIA_idPaque = paquete
						 		and REG_DIA_tipo = 'venta');
						 set aux_producido = (select SUM(REG_DIA_CANTIDAD) from REGISTRO_DIA where REG_DIA_idPaque = paquete
						 		and REG_DIA_tipo = 'produccion');
						 set aux_moje = (select SUM(REG_DIA_CANTIDAD) from REGISTRO_DIA where REG_DIA_idPaque = paquete
						 		and REG_DIA_tipo = 'moje');
                         
                         if aux_venta is null then
							set aux_venta = 0;
                         end if;
                         if aux_producido is null then
							set aux_producido = 0;
                         end if;
                         if aux_moje is null then
							set aux_moje = 0;
                         end if;
						 update INVENTARIO_PAN set INV_PAN_cantTotal = (aux_producido - aux_venta - aux_moje);
					 if done then
						leave loop1;
					end if;
			  end LOOP loop1;
		  close cursor1;
			commit;
		end &&
delimiter ;

-- MANEJO DEL MOVIMIENTO DE LA CAJA &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
-- &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
-- &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
drop procedure exiscaja;
delimiter &&
	create procedure exisCaja(fecha date)-- ya &&
		begin
			declare aux_exis int;
            set aux_exis = (select CAJ_gastos from CAJA where CAJ_fecha = fecha);
			if aux_exis is null then
				insert into CAJA values (fecha,0,0,0,0,0);
			end if;
        end &&    
delimiter ;


drop procedure actualizarCaja;
delimiter &&
	create procedure actualizarCaja(fecha date)-- ya &&
		begin
			start transaction; 
				
				call exisCaja(fecha);
                
				-- ventas
				update CAJA join VENTA set CAJ_ventas = sum(VENT_valorTotal) 
					where VENT_fecha = CAJ_fecha;
				-- COSTOS
				update CAJA join PEDIDO set CAJ_costos = sum(PED_precioTotal)
					where PED_fecha = CAJ_fecha;
				-- GASTOS
				update CAJA join GASTO set CAJ_gastos = sum(GAS_valor)
					where GAS_fecha = CAJ_fecha;
				-- ingresos
				update CAJA join INGRESO set CAJ_ingresos = sum(ING_valor)
					where ING_fecha = CAJ_fecha;
				-- PROVISIONES
				commit;
		end &&
delimiter ;

drop function sumaDineDiario;
delimiter &&
	create function sumaDineDiario(fecha date,tipo varchar(15)) returns int-- YA &&
		begin 
			declare aux_cantidad int default -1;

			if tipo = 'venta' then
				set aux_cantidad = (select SUM(VENT_valorTotal) from VENTA where VENT_fecha = fecha);
			end if;

			if tipo = 'gasto' then
				set aux_cantidad = (select SUM(GAS_valorTotal) from GASTO where GAS_fecha = fecha);
			end if;

			if tipo = 'costo' then
				set aux_cantidad = costoProduccionDia(fecha);
			end if;
            
			return aux_cantidad;
		end &&
delimiter ;


drop function costoProduccionDia;
delimiter &&
	create function costoProduccionDia(fecha date) returns int-- ya&&
		begin
			declare aux_cantidad int;
			declare aux_rece varchar(30);
			set aux_cantidad = (select sum(ITE_REC_precio) from ITEM_RECETA join CREACION join RECETA
			 ON ITE_REC_nombre = REC_nombre and REC_nombre = CRE_idRece where CRE_fecha = fecha);
			return aux_cantidad;
		end &&
delimiter ;

-- &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
-- &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&


-- INICIO - FIN DE OPERACIONES DIARIAS DEL SISTEMA &&&&&&&&&&&&& 
delimiter &&
	create procedure INI_OPERACIONES(estado boolean)
		begin 
			-- aqui va eliminar todos los registros no finalizados y el descuento de mercancia de inventario
			if estado then
				delete from 
			end if;
		end &&
delimiter ;
-- &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&


-- GASTOS &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
-- &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&


drop procedure hacerGastoCaja;
delimiter &&
	create procedure hacerGastoCaja(fecha int,concepto varchar(60),valor int,inout valorOut varchar(7))-- ya &&
		begin
			declare aux_fecha date;
			declare aux_caja int;
			declare aux_banco int;
			start transaction;
			call exisCaja(fecha);

			set aux_caja = dineroCaja(fecha);
			set aux_banco = dineroBanco();


			if valor > aux_caja then
				if valor > aux_banco then
					set valorOut = 'falta';
						else
							set valorOut = 'banco';
				end if;

					else
						insert into GASTO values(null,fecha,concepto,valor);
						call actualizarCaja(fecha);
			end if;
	
			commit;
		end &&
delimiter ;

drop procedure hacerGastoBanco;
delimiter &&
	create procedure hacerGastoBanco(fecha int,concepto varchar(60),valor int,inout valorOut varchar(7))
		label1:begin
			declare aux_fecha date;
			declare aux_caja int;
			declare aux_banco int;
			start transaction; 
            
			call exisCaja(fecha);
			set aux_caja = dineroCaja(fecha);
			set aux_banco = dineroBanco();


			if valor > aux_banco then
				if valor > aux_caja then
					set valorOut = 'falta';
                    leave label1;
						else
							set valorOut = 'caja';
				end if;

					else
						-- insert into GASTO values(null,fecha,concepto,valor);
						insert into BANCO values (null,fecha,'retiro',valor);
						call actualizarCaja(fecha);
			end if;
			commit;
		end &&
delimiter ;


drop function dineroCaja;
delimiter &&
	create function dineroCaja(fecha date) returns int-- YA &&
		begin
			declare aux_ventas int;
			declare aux_costos int;
			declare aux_gastos int;
			declare aux_provLabo int;
			declare aux_ingresos int;
			declare aux_banco int;
			declare aux_salida int;

			call actualizarCaja(fecha);

			set aux_ventas = (select sum(CAJ_ventas) from CAJA);
			set aux_costos = (select sum(CAJ_costos) from CAJA);
			set aux_gastos = (select sum(CAJ_gastos) from CAJA);
			set aux_provLabo = (select sum(CAJ_provLabo) from CAJA);
			set aux_ingresos = (select sum(CAJ_ingresos) from CAJA);

			set aux_salida = (aux_ventas + aux_ingresos - aux_costos - aux_gastos - aux_provLabo);
			return aux_salida;
		end &&
delimiter ;


-- BANCO &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
drop function dineroBanco;
delimiter &&
	create function dineroBanco() returns int-- ya&&
		begin 
			declare aux_consig int;
			declare aux_reti int;
			declare aux_salida int;

			set aux_consig = (select sum(BAN_cantidad) from BANCO where BAN_tipo = 'consignacion');
			set aux_reti = (select sum(BAN_cantidad) from BANCO where BAN_tipo = 'retiro');

			set aux_salida = (aux_consig - aux_reti);
			return aux_salida;
		end &&
delimiter ;

drop procedure consignarBanco;
delimiter &&
	create procedure consignarBanco(fecha date,cant int, inout valorOut varchar(7))-- YA &&
		begin
        declare aux_caja int;
			start transaction;
				set aux_caja = dineroCaja(fecha);
				if aux_caja < cant then
					set valorOut = 'falta';
						else
							insert into GASTO values (null,fecha,'banco',cant);
							insert into BANCO values (null,fecha,'consignacion',cant);
							set valorOut = 'bien';
							call actualizarCaja(fecha);
				end if;
			commit;
		end &&
delimiter ;


drop procedure retirarBanco;
delimiter &&
	create procedure retirarBanco(fecha date,cant int, inout valorOut varchar(7))-- ya &&
		begin
			declare aux_banco int;
			start transaction;
				set aux_banco = dineroBanco();
				if aux_banco < cant then
					set valorOut = 'falta';
						else
							insert into INGRESO values (null,fecha,'banco',cant);
							insert into BANCO values (null,fecha,'retiro',cant);
							set valorOut = 'bien';
							call actualizarCaja(fecha);
				end if;
			commit;
		end &&
delimiter ;



-- NOMINA &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
drop procedure prestarEmpleados;
delimiter && 
	create procedure prestarEmpleados(fecha date,empleado int, valor int,inout valorOut varchar(7))-- ya &&
		begin
			declare aux_caja int;
			start transaction;
				set aux_caja = dineroCaja(fecha);
				if aux_caja < valor then
					set valorOut = 'falta';
						else
							update NOMINA set NOM_adelantoPeriodo = NOM_adelantoPeriodo + valor where
								NOM_idEmple = empleado;
							insert into GASTO values (null,fecha,'adelanto',valor);
							call actualizarCaja(fecha);
							set valorOut = 'bien';
				end if;
			commit;
		end &&
delimiter ;

-- DEUDAS DE CUALQUIER TIPO

drop procedure deudaMateriaPrima;
delimiter &&
	create procedure deudaMateriaPrima(ref int,inout valorOut varchar(7))-- ya &&
		begin
			declare aux_fecha date;
			declare aux_valor int;
			declare aux_tercero varchar(30);
			declare aux_tercero_id varchar(30);
			declare aux_tercero_telefono bigint(16);
			declare aux_estado varchar(15);
            
			start transaction;
            
				set aux_estado = (select PED_estado from PEDIDO where PED_code = ref);

				if aux_estado = 'finalizado' then
					set aux_fecha = (select PED_fecha from PEDIDO where PED_code = ref);
					set aux_valor = (select PED_precioTotal from PEDIDO where PED_code = ref);
					set aux_tercero = (select PRO_nomEmpresa from PEDIDO join PROVEEDOR on PED_idProve = POR_code where PED_code = ref);
					set aux_tercero_id = (select PRO_nit from PEDIDO join PROVEEDOR on PED_idProve = POR_code where PED_code = ref);
					set aux_tercero_telefono = (select PRO_telefono from PEDIDO join PROVEEDOR on PED_idProve = POR_code where PED_code = ref);
					
					insert into DEUDA values (null,aux_tercero,aux_tercero_id,aux_tercero_telefono,'materia',aux_fecha,aux_valor);

						else
							set valorOut = 'falta';
				end if;
			commit;
		end &&
delimiter ;

drop procedure agregarDeuda;
delimiter &&
	create procedure agregarDeuda(fecha date,nombreTer varchar(30),id varchar(30),telefono bigInt(16),concepto varchar(45),valor int)
    begin
		insert into DEUDA values (null,nombreTer,id,telefono,concepto,fecha,valor);
    end &&
delimiter ;


drop procedure pagarDeuda;
delimiter &&
	create procedure pagarDeuda(fecha date,ref int,efectivo boolean,valorOut varchar(7))
    label1:begin
		declare aux_dispo int;
        declare aux_deuda int;
		start transaction;
			set aux_deuda = (select DEU_valor from DEUDA where DEU_code = ref);
            
            if efectivo then
				set aux_dispo = dineroCaja(fecha);
					else
						set aux_dispo = dineroBanco();
            end if;
            -- hacerGastoCaja(fecha int,concepto varchar(60),valor int,inout valorOut varchar(7))
            
            if aux_deuda <= aux_dispo then-- el dinero di alcanza
				if efectivo then
					call hacerGastoCaja(fecha,'deuda',aux_deuda,@salida);
						else
							call hacerGastoBanco(fecha,'deuda',aux_deuda,@salida);
                end if;
                insert into DEUDA_PAGADA select * from DEUDA where DEU_code = ref;
                delete from DEUDA where DEU_code = ref;
                call actualizarCaja(fecha);
					else-- el dinero no alcanza
						set valorOut = 'falta';
            end if;
        commit;
    end &&
delimiter ;


drop procedure prestamoACaja;
delimiter &&
	create procedure prestamoACaja(fecha date,nombreTer varchar(30),id varchar(30),telefono bigInt(16),concepto varchar(45),valor int)
    begin
		start transaction;
			insert into INGRESO values(null,fecha,concepto,valor);
            insert into DEUDA values (null,nombreTer,id,telefono,concepto,fecha,valor);
            call actualizarCaja(fecha);
        commit;
    end &&
delimiter ;

drop procedure prestamoABanco;
delimiter &&
	create procedure prestamoABanco(fecha date,nombreTer varchar(30),id varchar(30),telefono bigInt(16),concepto varchar(45),valor int)
    begin
		start transaction;
			insert into BANCO values (null,fecha,'consignacion',valor);
            insert into DEUDA values (null,nombreTer,id,telefono,concepto,fecha,valor);
        commit;
    end &&
delimiter ;



-- MOVIMIENTOS DE PERIODO O DIARIOS &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
-- &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&



-- CREACION DE USUARIOS, PERMISOS Y COSAS DE LA BASE &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
-- &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

drop function agregarCategoriaPan;
delimiter &&
	create function agregarCategoriaPan(nombre varchar(30),precioCalle int) returns varchar(7)
    begin	
		declare aux_exis int;
      
        set aux_exis = (select PAN_CAT_precioCalle from PAN_CATEGORIA where PAN_CAT_nombre like nombre);
        
        if aux_exis is not null then
			insert into PAN_CATEGORIA values (nombre,precioCalle);
			return ('bien');
                else
					return ('mal');
        end if;
    end &&
delimiter ;


drop function agregarPan;
delimiter &&
	create function agregarPan(nombre varchar(30),categoria varchar(30)) returns int
	begin
		declare aux_exis_cat int;
        declare aux_exis_pan int;
        
        set aux_exis_cat = (select PAN_CAT_precioCalle from PAN_CATEGORIA where PAN_CAT_nombre = categoria);
        set aux_exis_pan = (select PAN_CODE from PAN where PAN_nombre like nombre);
        
        if aux_exis_cat is null or aux_exis_pan is not null then
			return -1;
        end if;
        
        insert into PAN values (null,nombre,categoria,0);
        return last_insert_id();
    end &&
delimiter ;

drop procedure crearPaque;
delimiter &&
	create procedure crearPaque(nombre varchar(30),pan int,categoria varchar(30),numPorPaq int, empaque int,precio int,valorOut varchar(7))
    label1:begin
		declare aux_exis_cat int;
        declare aux_exis_pan int;
        declare aux_exis_paq int;
        declare aux_exis_emp int;
        
		start transaction;
			  set aux_exis_cat = (select PAN_CAT_precioCalle from PAN_CATEGORIA where PAN_CAT_nombre = categoria);
			  set aux_exis_pan = (select PAN_CODE from PAN where PAN_nombre = pan);
			  set aux_exis_paq = (select PAQ_numPorPaq from PAQUETE where PAQ_nombre = nombre);
              set aux_exis_emp = (select MAT_PRI_code from MATERIA_PRIMA where MAT_PRI_code = empaque);
              
		if aux_exis_cat is null or aux_exis_pan is null or aux_exis_emp is null or aux_exis_emp is not null then
			set valorOut = mal;
            leave label1;
        end if;
        
		insert into PAQUETE values (nombre,pan,categoria,numPorPaq,empaque,precio);
        insert into INVENTARIO_PAN values (nombre,0);
        commit;
    end &&
delimiter ;

-- insertar unidades de medida y categorias de materia prima a mano

drop procedure crearEmpaque;
delimiter &&
	create procedure crearEmpaque(nombre varchar(30),marca varchar(30),undMed varchar(30),presentacion varchar(30),precio int,inout codeOut int)
   label1:begin
		declare aux_exis int;
        declare aux_exis_emp int;
		start transaction;
			set aux_exis = (select MAT_PRI_code from MATERIA_PRIMA where MAT_PRI_nombre = nombre);
			set aux_exis_emp = (select MAT_PRI_code from MATERIA_PRIMA where MAT_PRI_code = empaque);
             
            if aux_exis is not null or aux_exis_emp is null then
				set codeOut = -1;
				leave label1;
            end if;
            insert into MATERIA_PRIMA values (null,nombre,marca,undMed,presentacion,precio,'empaque',cantidad,null);
            set codeOut = last_insert_id();
            insert into INVENTARIO_MATERIA_PRIMA values (codeOut,0);
        commit;
    end &&
delimiter ;


drop procedure agregarMateriaPrima;
delimiter &&
	create procedure agregarMateriaPrima(nombre varchar(30),marca varchar(30),medida varchar(30),presentacion varchar(30),precio int,categ varchar(30),fechaCad date,inout codeOut int)
	label1:begin
		declare aux_exis int;
        declare aux_exis_med varchar(30);
        declare aux_exis_categ varchar(30);
        
		start transaction;
			set aux_exis = (select MAT_PRI_code from MATERIA_PRIMA where MAT_PRI_nombre = nombre);
			set aux_exis_categ = (select MAT_PRI_CAT_nombre from MATERIA_PRIMA_CATEGORIA where MAT_PRI_CAT_nombre = categ);
            set aux_exis_med = (select UND_MED_nombre from UNIDAD_MEDIDA where UND_MED_nombre = medida);
		
        if aux_exis is not null or aux_exis_categ is null or aux_exis_med is null then
			set codeOut = -1;
            leave label1;
        end if;
        
        insert into MATERIA_PRIMA values (null,nombre,marca,medida,presentacion,precio,categoria,fechaCad);
        set codeOut = last_insert_id();
        insert into INVENTARIO_MATERIA_PRIMA values(codeOut,0);
        commit;
    end &&
delimiter ;

-- creacion de usuarios de base o de acceso *************

drop function crearCargoEmpleado;
delimiter &&
	create function crearCargoEmpleado(nombre varchar(15),permiso int)returns varchar(7)
    begin
		declare aux_exis varchar(15);
        set aux_exis = (select EMP_CAR_nombre from EMPLEADO_CARGO where EMP_CAR_nombre = nombre);
        if aux_exis is not null then
			return 'mal';
        end if;
        insert into EMPLEADO_CARGO values(nombre,permiso);
        return 'bien';
    end &&
delimiter ;

drop function crearEmpleado;
delimiter &&
	create function crearEmpleado(nombre varchar(30),apellido varchar(30),cedula bigint(17),fecNac date,tele bigint(17),dire varchar(45),email varchar(45),cargo varchar(15),horaIn datetime,horaOut datetime,salario int)returns int
    begin
		declare aux_exis bigint(17);
        declare aux_exis_carg varchar(15);
        
        set aux_exis_carg = (select EMP_CAR_nombre from EMPLEADO_CARGO where EMP_CAR_nombre = nombre);
        set aux_exis = (select EMP_cedula from EMPLEADO where EMP_cedula = cedula);
        
        if aux_exis_carg is  null or aux_exis is not null then
			return -1;
        end if;
        
        insert into EMPLEADO values(null,nombre,apellido,cedula,fecNac,tele,dire,email,cargo,horaIn,horaOut,salario);
        
        return last_insert_id();
    end &&
delimiter ;

drop procedure crearVendedor;
delimiter &&
	create procedure crearVendedor(nombre varchar(30),apellido varchar(30),cedula bigint(17),fecNac date,tele bigint(17),dire varchar(45),email varchar(45),horaIn datetime,horaOut datetime,salario int,ruta int,subsidio int,inout codeOut int)
    label1:begin
		declare aux_exis bigint(17);
        declare aux_exis_carg varchar(15);
        declare aux_exis_ruta int;
        start transaction;
        
        set aux_exis_carg = (select EMP_CAR_nombre from EMPLEADO_CARGO where EMP_CAR_nombre = nombre);
        set aux_exis = (select EMP_cedula from EMPLEADO where EMP_cedula = cedula);
        set aux_exis_ruta = (select RUT_code from RUTA where RUT_code = ruta);
        
        if aux_exis_ruta is null or aux_exis_carg is  null or aux_exis is not null then
			set codeOut = -1;
            leave label1;
        end if;
        
        insert into EMPLEADO values(null,nombre,apellido,cedula,fecNac,tele,dire,email,cargo,horaIn,horaOut,salario);
        set codeOut = last_insert_id();
        insert into VENDEDOR values (codeOut,ruta,subsidio);
		commit;
    end &&
delimiter ;

drop function crearUsuario;
delimiter &&
	create function crearUsuario (login varchar(30),pass varchar(30),empleado int,permiso int) returns varchar(7)
    begin
		declare aux_exis varchar(30);
        set aux_exis = (select USU_login from USUARIO where USU_login = login);
        
        if aux_exis is null then
			insert into USUARIO values(login,pass,empleado,permiso);
            return 'bien';
				else
					return 'mal';
        end if;
    end &&
delimiter ;


drop function  crearProveedor;
delimiter &&
	create function crearProveedor(nomEmp varchar(45),nit varchar(30),nomPersona varchar(45),dir varchar(45),tel bigint(15),email varchar(45),concep varchar(45)) returns int
	begin
		declare aux_exis int;
        set aux_exis = (Select PRO_code from PROVEEDOR where PRO_nomEmpresa = nomEmp and PRO_nomPersona = nomPersona);
        if aux_exis is null then
				insert into PROVEEDOR values (null,nomEmp,nit,nomPersona,dir,tel,email,concep);
                return last_insert_id();
				else
					return -1;
        end if;
    end &&
delimiter ;

drop function crearCliente;
delimiter &&
create function crearCliente(nombre varchar(30),apellido varchar(30),id varchar(17),telCel bigint(17),telFij bigint(17),dir varchar(45),ruta int,email varchar(30),concep varchar(45)) returns int
	begin 
		declare aux_exis int;
        set aux_exis = (select CLI_CODE from CLIENTE where CLI_nombre = nombre and CLI_apellido = apellido and CLI_direccion  like dir);
        
        if aux_exis then
			insert into CLIENTE values (null,nombre,apellido,id,telCel,telFij,dir,ruta,email,concep);
            return last_insert_id();
				else
					return -1;
        end if;
    end &&
delimiter ;


drop procedure ascenderClitente;
delimiter &&
create procedure ascenderCliente(codi int,paquete int,precioFull int,precioMin int,minVol int,vendePor float,concep varchar(45),valorOut varchar(7))
	label1:begin
		declare aux_exis int;
        set aux_exis = (select CLI_ESP_minVol from CLIENTE_ESPECIAL where CLI_ESP_idClien = codi and CLI_ESP_idPaque = paque);
		
        if isEspecial(codi) and aux_exis is null then
			insert into CLIENTE_ESPECIAL values (codi,paquete,precioFull,preciomin,minVol,vendePor,concep);
            set valorOut = 'bien';
                else
                set valorOut = 'mal';
                leave label1;
        end if;
	end &&
delimiter ;







-- TENER EN CUENTA EN LA VENTA QUE SI EL VENDEDOR RECIBE SUBSIDIO O NO
-- INSERTAR TABLAS DESDE ACCESS 
-- HACER QUE CUANDO SE INSERTE UNA MATERIA PRIMA NUEVA CON PRECIO Y TAL SE CALCULE EL PRECIO UNIDAD


















