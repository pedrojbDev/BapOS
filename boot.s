/*
 * Constantes do cabeçalho Multiboot.
 *
 * Esses valores informam ao GRUB como o kernel deve ser carregado.
 *
 * ALIGN ativa o bit 0, solicitando que os módulos carregados sejam
 * alinhados em limites de página de memória.
 *
 * MEMINFO ativa o bit 1, solicitando que o GRUB forneça informações
 * sobre a memória disponível do sistema.
 *
 * FLAGS combina ambas as opções usando a operação OR bit a bit:
 *
 *     ALIGN   = 00000001 (1)
 *     MEMINFO = 00000010 (2)
 *     -------------------------
 *     FLAGS   = 00000011 (3)
 *
 * MAGIC é a assinatura definida pelo padrão Multiboot. O GRUB procura
 * esse valor nos primeiros KiB do arquivo para identificar que ele é
 * um kernel compatível com Multiboot.
 *
 * CHECKSUM é calculado de forma que:
 *
 *     MAGIC + FLAGS + CHECKSUM = 0
 *
 * Isso permite que o GRUB valide a integridade do cabeçalho antes de
 * carregar o kernel.
 */

.set ALIGN, 1<<0
.set MEMINFO, 1<<1
.set FLAGS, ALIGN | MEMINFO
.set MAGIC, 0x1BADB002
.set CHECKSUM, -(MAGIC + FLAGS)

/*
 * Cabeçalho Multiboot gravado no binário do kernel.
 *
 * A seção .multiboot guarda os três valores que o GRUB precisa encontrar
 * para reconhecer este arquivo como um kernel compatível com Multiboot.
 *
 * O alinhamento de 4 bytes é obrigatório porque o padrão Multiboot exige
 * que o cabeçalho esteja alinhado em uma fronteira de 32 bits.
 *
 * Cada diretiva .long grava um valor de 32 bits no binário:
 *
 *     MAGIC     -> assinatura Multiboot
 *     FLAGS     -> opções solicitadas ao bootloader
 *     CHECKSUM  -> validação: MAGIC + FLAGS + CHECKSUM = 0
 */

.section .multiboot
.align 4
.long MAGIC
.long FLAGS
.long CHECKSUM

/*
 * Reserva da stack inicial do kernel.
 *
 * A seção .bss é usada para dados não inicializados. Isso permite reservar
 * espaço em memória sem aumentar desnecessariamente o tamanho do arquivo
 * final do kernel.
 *
 * O alinhamento de 16 bytes é necessário porque o compilador espera que a
 * pilha esteja corretamente alinhada conforme a ABI usada em x86.
 *
 * stack_bottom marca o início da área reservada.
 *
 * .skip 16384 reserva 16 KiB para a stack inicial.
 *
 * stack_top marca o final da área reservada. Como a stack em x86 cresce
 * para baixo, o registrador ESP será configurado para apontar para
 * stack_top antes de chamar o código em C/C++.
 */

.section .bss   
.align 16
stack_bottom:
.skip 16384
stack_top:

/*
 * Ponto de entrada do kernel.
 *
 * A seção .text contém o código executável do kernel.
 *
 * O símbolo _start é marcado como global para que o linker consiga
 * encontrá-lo e usá-lo como ponto de entrada do kernel.
 *
 * Quando o GRUB terminar de carregar o kernel na memória, ele transfere
 * a execução para este endereço. A partir daqui, o kernel assume o
 * controle da CPU.
 */

.section .text
.global _start
_start:

    /*
    * Inicializa a stack do kernel.
    *
    * O registrador ESP (Stack Pointer) deve apontar para uma área válida
    * de memória antes que qualquer código em C/C++ seja executado.
    *
    * Como a stack em arquiteturas x86 cresce de endereços maiores para
    * menores, ESP é configurado para apontar para stack_top, o final da
    * área reservada anteriormente.
    *
    * A partir deste ponto, chamadas de função, variáveis locais e demais
    * operações que dependem da stack passam a funcionar corretamente.
    */

    mov $stack_top, %esp   

    /*
    * Transfere a execução para o kernel em C/C++.
    *
    * A função kernel_main representa o ponto de entrada da parte de alto
    * nível do kernel. Antes desta chamada, o código Assembly já configurou
    * a stack inicial, permitindo que chamadas de função, variáveis locais
    * e convenções básicas da ABI funcionem corretamente.
    *
    * A instrução call salva o endereço de retorno na stack e desvia a
    * execução para kernel_main.
    */

    call kernel_main  

    /*
    * Loop final de segurança.
    *
    * Em teoria, kernel_main não deve retornar. Depois que o bootloader
    * transfere o controle para o kernel, não existe um ambiente anterior
    * confiável para onde retornar.
    *
    * A instrução cli desativa interrupções mascaráveis da CPU.
    *
    * O rótulo local 1 marca o início do loop. A instrução hlt coloca a CPU
    * em estado de espera, reduzindo uso de processamento até que ocorra
    * alguma interrupção.
    *
    * Como as interrupções comuns foram desativadas, o processador permanece
    * parado. Caso acorde por algum evento especial, jmp 1b faz a execução
    * voltar para o rótulo 1 anterior, mantendo o kernel preso em um loop
    * infinito seguro.
    */

    cli
1:  hlt
    jmp 1b


    /*
    * Define o tamanho do símbolo _start.
    *
    * O ponto "." representa a posição atual no código. Ao calcular
    * ". - _start", obtemos a quantidade de bytes entre o início de _start
    * e o ponto atual, ou seja, o tamanho da rotina de inicialização.
    *
    * Essa informação é útil para ferramentas de análise e depuração, como
    * objdump, readelf e GDB. Ela não altera diretamente o fluxo de execução
    * do kernel.
    */

.size _start, . - _start