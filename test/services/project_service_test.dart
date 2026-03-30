import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_asistencia/services/project_service.dart';
import 'package:qr_asistencia/repositories/project_repository.dart';

class MockProjectRepository extends Mock implements ProjectRepository {}

void main() {
  late MockProjectRepository mockRepository;

  setUp(() {
    mockRepository = MockProjectRepository();
    ProjectService.mockRepository = mockRepository;
  });

  tearDown(() {
    ProjectService.mockRepository = null;
  });

  group('ProjectService Lectura', () {
    test('getProyectos devuelve una lista formateada en éxito', () async {
      final mockData = [
        {'No.': 1, 'NameProyect': 'Proyecto A', 'Client': 'Cliente 1', 'OC': 'OC1'},
        {'No.': 2, 'NameProyect': null, 'Client': null, 'OC': null}, // Probar valores nulos
      ];

      when(() => mockRepository.getProyectos()).thenAnswer((_) async => mockData);

      final result = await ProjectService.getProyectos();

      expect(result.length, 2);
      expect(result[0], {'numero': '1', 'nombre': 'Proyecto A', 'cliente': 'Cliente 1', 'oc': 'OC1'});
      expect(result[1], {'numero': '2', 'nombre': 'Sin nombre', 'cliente': '', 'oc': ''});
    });

    test('getProyectos devuelve lista vacía si ocurre un error', () async {
      when(() => mockRepository.getProyectos()).thenThrow(Exception('Error de base de datos'));

      final result = await ProjectService.getProyectos();

      expect(result, []);
    });
  });

  group('ProjectService Creación', () {
    test('crearProyecto retorna null en éxito', () async {
      when(() => mockRepository.crearProyecto(
            numero: any(named: 'numero'),
            nombre: any(named: 'nombre'),
            cliente: any(named: 'cliente'),
            oc: any(named: 'oc'),
          )).thenAnswer((_) async {});

      final result = await ProjectService.crearProyecto('123', 'Nuevo Proyecto', 'Cliente X', 'OC2');

      expect(result, isNull);
      verify(() => mockRepository.crearProyecto(numero: '123', nombre: 'Nuevo Proyecto', cliente: 'Cliente X', oc: 'OC2')).called(1);
    });

    test('crearProyecto retorna null en cliente y oc vacíos si se envian cadenas vacias', () async {
      when(() => mockRepository.crearProyecto(
            numero: any(named: 'numero'),
            nombre: any(named: 'nombre'),
            cliente: any(named: 'cliente'),
            oc: any(named: 'oc'),
          )).thenAnswer((_) async {});

      final result = await ProjectService.crearProyecto('123', 'Nuevo Proyecto', '', '');

      expect(result, isNull);
      verify(() => mockRepository.crearProyecto(numero: '123', nombre: 'Nuevo Proyecto', cliente: null, oc: null)).called(1);
    });

    test('crearProyecto retorna mensaje de error si falla', () async {
      when(() => mockRepository.crearProyecto(
            numero: any(named: 'numero'),
            nombre: any(named: 'nombre'),
            cliente: any(named: 'cliente'),
            oc: any(named: 'oc'),
          )).thenThrow(Exception('Error al insertar'));

      final result = await ProjectService.crearProyecto('123', 'Nuevo Proyecto', 'Cliente X', 'OC2');

      expect(result, 'No se pudo crear el proyecto. Verifica los datos o tus permisos.');
    });
  });

  group('ProjectService Edición', () {
    test('editarProyecto retorna null en éxito', () async {
      when(() => mockRepository.editarProyecto(
            oldNumero: any(named: 'oldNumero'),
            nuevoNumero: any(named: 'nuevoNumero'),
            nuevoNombre: any(named: 'nuevoNombre'),
            cliente: any(named: 'cliente'),
            oc: any(named: 'oc'),
          )).thenAnswer((_) async {});

      final result = await ProjectService.editarProyecto('123', '124', 'Nombre Actualizado', 'Cliente Y', 'OC3');

      expect(result, isNull);
      verify(() => mockRepository.editarProyecto(
          oldNumero: '123', nuevoNumero: '124', nuevoNombre: 'Nombre Actualizado', cliente: 'Cliente Y', oc: 'OC3')).called(1);
    });

    test('editarProyecto manda null en cliente y oc si se envían cadenas vacías', () async {
      when(() => mockRepository.editarProyecto(
            oldNumero: any(named: 'oldNumero'),
            nuevoNumero: any(named: 'nuevoNumero'),
            nuevoNombre: any(named: 'nuevoNombre'),
            cliente: any(named: 'cliente'),
            oc: any(named: 'oc'),
          )).thenAnswer((_) async {});

      final result = await ProjectService.editarProyecto('123', '124', 'Nombre Actualizado', '', '');

      expect(result, isNull);
      verify(() => mockRepository.editarProyecto(
          oldNumero: '123', nuevoNumero: '124', nuevoNombre: 'Nombre Actualizado', cliente: null, oc: null)).called(1);
    });

    test('editarProyecto retorna mensaje de error si falla', () async {
      when(() => mockRepository.editarProyecto(
            oldNumero: any(named: 'oldNumero'),
            nuevoNumero: any(named: 'nuevoNumero'),
            nuevoNombre: any(named: 'nuevoNombre'),
            cliente: any(named: 'cliente'),
            oc: any(named: 'oc'),
          )).thenThrow(Exception('Error al actualizar'));

      final result = await ProjectService.editarProyecto('123', '124', 'Nombre Actualizado', 'Cliente Y', 'OC3');

      expect(result, 'No se pudo actualizar el proyecto. Intenta de nuevo.');
    });
  });

  group('ProjectService Eliminación', () {
    test('eliminarProyecto retorna null en éxito', () async {
      when(() => mockRepository.eliminarProyecto(any())).thenAnswer((_) async {});

      final result = await ProjectService.eliminarProyecto('123');

      expect(result, isNull);
      verify(() => mockRepository.eliminarProyecto('123')).called(1);
    });

    test('eliminarProyecto retorna mensaje de error si falla', () async {
      when(() => mockRepository.eliminarProyecto(any())).thenThrow(Exception('Error al eliminar'));

      final result = await ProjectService.eliminarProyecto('123');

      expect(result, 'No se pudo eliminar el proyecto. Intenta de nuevo.');
    });
  });
}
