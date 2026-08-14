FROM sagemath/sagemath:10.7

ARG NB_UID=1000
ARG NB_USER=sage

USER root
RUN apt update && apt install -y python3 python3-pip git
USER ${NB_UID}
ENV PATH="${PATH}:${HOME}/.local/bin"
RUN pip3 install notebook

# register the Sage kernel under the name the notebooks reference
RUN mkdir -p $HOME/.local/share/jupyter/kernels && \
    ln -s $(sage -sh -c 'ls -d $SAGE_VENV/share/jupyter/kernels/sagemath') \
          $HOME/.local/share/jupyter/kernels/sagemath-10.7

# install the packages used by the lecture notebooks
RUN sage -pip install sage_acsv

# Build ore_algebra's compiled helpers against this image's own Sage and Cython.
RUN sage -pip install --no-build-isolation git+https://github.com/mkauers/ore_algebra.git \
 || sage -pip install git+https://github.com/mkauers/ore_algebra.git

# If any compiled accelerator still mismatches, remove them all: ore_algebra then
# falls back to its pure-Python implementations (slower, but correct)
RUN sage -c "import ore_algebra.analytic.dac_sum_c, ore_algebra.analytic.naive_sum_c, ore_algebra.analytic.binary_splitting_arb, ore_algebra.analytic.eval_poly_at_int; print('compiled accelerators OK')" \
 || sage -c "import glob, os, ore_algebra; d = os.path.dirname(ore_algebra.__file__); [os.remove(f) for f in glob.glob(d + '/**/*.so', recursive=True)]; print('removed mismatched ore_algebra accelerators')"

# Fail the image build if numeric analytic continuation does not work
RUN sage -c "from ore_algebra import OreAlgebra; Pols = QQ['z']; z = Pols.gen(); Dz = OreAlgebra(Pols, 'Dz').gen(); print((2*z*Dz - 1).numerical_solution(ini=[1], path=[1, I, -1]))"

RUN sage -pip install git+https://github.com/ACSVMath/sage_periods.git

WORKDIR ${HOME}/notebooks
COPY --chown=${NB_UID}:${NB_UID} . .
USER root
RUN chown -R ${NB_UID}:${NB_UID} .
USER ${NB_UID}

ENTRYPOINT []
